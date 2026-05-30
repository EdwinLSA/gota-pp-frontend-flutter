import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:app_pp_sem_6/secrets.dart'; // groqApiKey y groqModelo (no se sube al repo)

// colores de la app (mismos del home para mantener coherencia)
const Color colorBoton = Color(0xFF2F3D52);
const Color colorFondo = Color(0xFFE6E2DC);

// instrucciones del LLM: persona experta + contexto (los mismos datos demo
// del dashboard, en texto) para aterrizar las respuestas.
const String promptSistema =
    'Eres un asistente profesional experto en agricultura y manejo del agua '
    'para zonas áridas del norte de México. Respondes SIEMPRE en español, de '
    'forma clara, cálida y breve (máximo 4 frases). Basa tus respuestas en '
    'este contexto actual de la parcela del usuario:\n'
    '- Recomendación de riego hoy: 3 L/m².\n'
    '- Agua ahorrada este mes: 5,800 L.\n'
    '- Humedad del suelo actual: 68%.\n'
    '- Riego recomendado últimos 7 días (L/m²): 3, 3, 5, 4, 3, 0, 3.\n'
    '- Ahorro acumulado por semana (L): 1200, 2900, 4300, 5800.\n'
    '- Precipitación esperada próximos días (mm): 0, 2, 12, 8, 0.\n'
    '- Temperatura últimos 7 días (°C): 24, 26, 31, 29, 25, 21, 23.\n'
    'Los datos provienen de satélites de la NASA, modelos propios y sensores '
    'y drones de socios. Cuando haya lluvia esperada, recomienda no regar. '
    'Si te preguntan algo fuera del tema de agua, riego o cultivos, redirige '
    'con amabilidad hacia esos temas.';

// aviso cuando se agota la cuota del "modelo gratis" (5 consultas al LLM).
const String mensajeLimite =
    '⏳ Llegaste al límite de tu modelo gratis (5 consultas). Se reactivará en '
    'aproximadamente 2 horas. Mientras tanto te sigo atendiendo con una versión '
    'más básica del asistente. 🤖';

// chat de la app. HIBRIDO: los chips de FAQ usan un bot LOCAL por palabras
// clave (instantaneo, offline); el texto libre llama a un LLM (Groq).
class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

// un mensaje del chat: el texto y si lo escribio el usuario o el asistente
class Mensaje {
  final String texto;
  final bool esUsuario;
  const Mensaje(this.texto, this.esUsuario);
}

class _ChatState extends State<Chat> {
  final TextEditingController controladorTexto = TextEditingController();
  final ScrollController controladorScroll = ScrollController();

  // preguntas rapidas que aparecen como "chips" para no tener que escribir
  final List<String> sugerencias = const [
    '¿Por qué regar hoy?',
    '¿Cuándo NO regar?',
    '¿Cuánta agua ahorro?',
    '¿De dónde salen los datos?',
  ];

  // historial de mensajes que se ve en pantalla. arranca con el saludo.
  final List<Mensaje> mensajes = [
    const Mensaje(
      'Hola 👋 Soy tu asistente de riego. Pregúntame por qué hoy se '
      'recomienda regar o no, o toca una de las sugerencias.',
      false,
    ),
  ];

  // memoria que se le manda al LLM: pares {role, content}. SIN persistencia.
  final List<Map<String, String>> memoriaLLM = [];

  // cuota del "modelo gratis": 5 consultas al LLM y luego pausa de 2 horas.
  // durante la pausa el chat sigue, pero con la version rustica (bot local).
  static const int maxConsultas = 5;
  static const Duration esperaBloqueo = Duration(hours: 2);
  int consultasLLM = 0; // consultas al LLM usadas en la ventana actual
  DateTime? bloqueadoHasta; // si != null, el LLM esta en pausa hasta esta hora

  bool cargando = false; // true mientras esperamos la respuesta del LLM

  // hay key valida configurada? si no, el texto libre cae al bot local.
  bool get hayLLM =>
      groqApiKey.isNotEmpty && groqApiKey != 'PEGA_TU_API_KEY_DE_GROQ_AQUI';

  @override
  void dispose() {
    controladorTexto.dispose();
    controladorScroll.dispose();
    super.dispose();
  }

  // quita acentos y pasa a minusculas para comparar palabras clave facil
  String normalizar(String t) {
    return t
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  // el "cerebro" del bot: devuelve una respuesta segun las palabras del mensaje
  String responder(String mensajeUsuario) {
    final t = normalizar(mensajeUsuario);

    if (t.contains('hola') || t.contains('buenas') || t.contains('buenos')) {
      return '¡Hola! 🌱 ¿En qué te ayudo hoy con tu riego?';
    }
    if (t.contains('gracias')) {
      return '¡Con gusto! Estoy para ayudarte a cuidar tu agua. 💧';
    }
    // por que NO regar / lluvia
    if (t.contains('lluvia') ||
        t.contains('llov') ||
        t.contains('no regar') ||
        t.contains('cuando no')) {
      return 'Cuando se esperan lluvias el suelo recibe agua natural. Regar de '
          'más desperdicia agua y puede dañar la raíz, por eso esos días la '
          'recomendación baja a 0 L/m².';
    }
    // calor
    if (t.contains('calor') || t.contains('sol') || t.contains('caluroso')) {
      return 'Con altas temperaturas el cultivo pierde más agua por '
          'evaporación. Por eso la recomendación sube hasta 5 L/m² para '
          'mantener la humedad.';
    }
    // cuanto / por que regar hoy
    if (t.contains('por que') ||
        t.contains('porque') ||
        t.contains('regar hoy') ||
        t.contains('cuanto') ||
        t.contains('hoy')) {
      return 'Hoy se recomiendan 3 L/m². Calculamos ese número con la humedad '
          'del suelo, la temperatura y la evapotranspiración, para que riegues '
          'justo lo necesario.';
    }
    // ahorro de agua
    if (t.contains('ahorr') || t.contains('agua')) {
      return 'Regando la cantidad exacta evitas desperdicio. Este mes llevas '
          'unos 5,800 L ahorrados frente al riego tradicional. 💧';
    }
    // de donde salen los datos
    if (t.contains('dato') ||
        t.contains('nasa') ||
        t.contains('satelite') ||
        t.contains('sensor') ||
        t.contains('mide') ||
        t.contains('como sab')) {
      return 'Combinamos datos de satélites de la NASA, nuestros propios '
          'algoritmos y, si tienes socios conectados, sus drones y sensores de '
          'humedad en el campo.';
    }
    // respuesta por defecto: orienta al usuario
    return 'Puedo ayudarte con: por qué regar hoy, cuándo NO regar, cuánta agua '
        'ahorras y de dónde salen los datos. ¿Qué te gustaría saber?';
  }

  // CHIPS DE FAQ: usan el bot LOCAL por palabras clave (instantaneo, offline).
  void enviarFAQ(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty || cargando) return;
    setState(() {
      mensajes.add(Mensaje(limpio, true));
      mensajes.add(Mensaje(responder(limpio), false));
    });
    bajarAlFinal();
  }

  // TEXTO LIBRE. Usa el LLM (Groq) hasta agotar la cuota de 5 consultas; luego
  // entra en pausa de 2 horas y sigue con la version rustica (bot local).
  Future<void> enviarLibre(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || cargando) return;

    // si ya paso la pausa de 2 horas, reactivamos el modelo gratis.
    if (bloqueadoHasta != null && DateTime.now().isAfter(bloqueadoHasta!)) {
      bloqueadoHasta = null;
      consultasLLM = 0;
      memoriaLLM.clear();
    }

    // usamos el LLM solo si hay key configurada y no estamos en pausa.
    final usarLLM = hayLLM && bloqueadoHasta == null;

    setState(() {
      mensajes.add(Mensaje(limpio, true));
      cargando = usarLLM; // el indicador "escribiendo..." solo aplica al LLM
    });
    controladorTexto.clear();
    bajarAlFinal();

    // version rustica: sin key o en pausa -> responde el bot local (instantaneo)
    if (!usarLLM) {
      setState(() => mensajes.add(Mensaje(responder(limpio), false)));
      bajarAlFinal();
      return;
    }

    // --- consulta al LLM ---
    String respuesta;
    try {
      respuesta = await llamarGroq(limpio);
    } catch (_) {
      respuesta = responder(limpio); // fallback al bot local si algo falla
    }
    memoriaLLM.add({'role': 'user', 'content': limpio});
    memoriaLLM.add({'role': 'assistant', 'content': respuesta});
    consultasLLM++;

    if (!mounted) return;
    setState(() {
      mensajes.add(Mensaje(respuesta, false));
      cargando = false;
      // se agoto la cuota del modelo gratis -> pausa de 2h + aviso al usuario
      if (consultasLLM >= maxConsultas) {
        bloqueadoHasta = DateTime.now().add(esperaBloqueo);
        memoriaLLM.clear();
        mensajes.add(const Mensaje(mensajeLimite, false));
      }
    });
    bajarAlFinal();
  }

  // hace la peticion a la API de Groq (compatible OpenAI) y regresa el texto.
  Future<String> llamarGroq(String mensajeUsuario) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    // armamos: system + memoria previa + el mensaje nuevo
    final mensajesApi = [
      {'role': 'system', 'content': promptSistema},
      ...memoriaLLM,
      {'role': 'user', 'content': mensajeUsuario},
    ];

    final respuesta = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $groqApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': groqModelo,
            'messages': mensajesApi,
            'temperature': 0.5,
            'max_tokens': 400,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (respuesta.statusCode != 200) {
      throw Exception('Groq respondio ${respuesta.statusCode}');
    }
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    final texto = datos['choices'][0]['message']['content'] as String;
    return texto.trim();
  }

  // hace scroll hasta el ultimo mensaje despues de dibujarlo
  void bajarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controladorScroll.hasClients) {
        controladorScroll.animateTo(
          controladorScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: colorBoton,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===== lista de mensajes =====
            Expanded(
              child: ListView.builder(
                controller: controladorScroll,
                padding: const EdgeInsets.all(16),
                // +1 si esta cargando, para mostrar la burbuja "escribiendo..."
                itemCount: mensajes.length + (cargando ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= mensajes.length) return burbujaEscribiendo();
                  return burbuja(mensajes[i]);
                },
              ),
            ),

            // ===== chips de preguntas rapidas =====
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in sugerencias)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text(s),
                        backgroundColor: Colors.white,
                        labelStyle: const TextStyle(color: colorBoton),
                        // bisel mas grueso para que combine con el resto de la app
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          side: BorderSide(color: colorBoton, width: 2.5),
                        ),
                        onPressed: () => enviarFAQ(s),
                      ),
                    ),
                ],
              ),
            ),

            // ===== barra para escribir =====
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controladorTexto,
                      enabled: !cargando,
                      textInputAction: TextInputAction.send,
                      onSubmitted: enviarLibre,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu pregunta...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // boton enviar (biselado, como el resto de la app)
                  Material(
                    color: cargando ? Colors.grey : colorBoton,
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: InkWell(
                      onTap: cargando
                          ? null
                          : () => enviarLibre(controladorTexto.text),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // burbuja "escribiendo..." mientras el LLM responde
  Widget burbujaEscribiendo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorBoton,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'escribiendo…',
              style: TextStyle(
                color: colorBoton,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // una burbuja de mensaje. usuario a la derecha (slate), bot a la izquierda (blanco)
  Widget burbuja(Mensaje m) {
    return Align(
      alignment: m.esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: m.esUsuario ? colorBoton : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          m.texto,
          style: TextStyle(
            color: m.esUsuario ? Colors.white : colorBoton,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
