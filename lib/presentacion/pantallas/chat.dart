import 'package:flutter/material.dart';

// colores de la app (mismos del home para mantener coherencia)
const Color colorBoton = Color(0xFF2F3D52);
const Color colorFondo = Color(0xFFE6E2DC);

// chat de la app. es un bot LOCAL: responde segun palabras clave del mensaje
// del usuario. no usa internet ni IA externa, todo es texto predefinido.
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

  // historial de mensajes. arranca con el saludo del asistente.
  final List<Mensaje> mensajes = [
    const Mensaje(
      'Hola 👋 Soy tu asistente de riego. Pregúntame por qué hoy se '
      'recomienda regar o no, o toca una de las sugerencias.',
      false,
    ),
  ];

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

  // envia un mensaje del usuario y agrega la respuesta del bot
  void enviar(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;

    setState(() {
      mensajes.add(Mensaje(limpio, true)); // mensaje del usuario
      mensajes.add(Mensaje(responder(limpio), false)); // respuesta del bot
    });
    controladorTexto.clear();
    bajarAlFinal();
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
                itemCount: mensajes.length,
                itemBuilder: (context, i) => burbuja(mensajes[i]),
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
                        side: const BorderSide(color: colorBoton),
                        labelStyle: const TextStyle(color: colorBoton),
                        onPressed: () => enviar(s),
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
                      textInputAction: TextInputAction.send,
                      onSubmitted: enviar,
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
                    color: colorBoton,
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: InkWell(
                      onTap: () => enviar(controladorTexto.text),
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
