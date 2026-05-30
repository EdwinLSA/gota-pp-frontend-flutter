import 'dart:async'; // para el Timer que cambia el estado del clima
import 'package:flutter/material.dart';

import 'package:app_pp_sem_6/presentacion/pantallas/graficos.dart';
import 'package:app_pp_sem_6/presentacion/pantallas/chat.dart';
import 'package:app_pp_sem_6/presentacion/pantallas/socios.dart';

// colores principales de la app
const Color colorBoton = Color(0xFF2F3D52); // botones / texto
const Color colorFondo = Color(0xFFE6E2DC); // fondo general (caqui)

// sombra suave para que el texto blanco se lea sobre la imagen de clima
const List<Shadow> sombraTexto = [
  Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
];

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // los 4 estados del clima (demo). cada uno define imagen de fondo, icono,
  // temperatura, litros recomendados y la accion. el numero es el protagonista.
  final List<Map<String, dynamic>> estados = [
    {
      'imagen': 'assets/clima/templado.png',
      'icono': Icons.wb_cloudy,
      'clima': 'Clima templado',
      'temp': '24°',
      'litros': '3',
      'accion': 'Riega hoy',
    },
    {
      'imagen': 'assets/clima/calor.png',
      'icono': Icons.wb_sunny,
      'clima': 'Día caluroso',
      'temp': '38°',
      'litros': '5',
      'accion': 'Riega más hoy',
    },
    {
      'imagen': 'assets/clima/templado.png',
      'icono': Icons.wb_cloudy,
      'clima': 'Clima templado',
      'temp': '23°',
      'litros': '3',
      'accion': 'Riega hoy',
    },
    {
      'imagen': 'assets/clima/lluvia.png',
      'icono': Icons.grain,
      'clima': 'Se espera lluvia',
      'temp': '19°',
      'litros': '0',
      'accion': 'No riegues hoy',
    },
  ];

  int estadoActual = 0; // que estado del clima se muestra ahora
  Timer? temporizador; // cambia de estado cada 7 segundos

  // nombres en espanol para armar la fecha sin paquetes extra
  static const dias = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  static const meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
    'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];

  @override
  void initState() {
    super.initState();
    // cada 7 segundos pasamos al siguiente estado del clima
    temporizador = Timer.periodic(const Duration(seconds: 7), (t) {
      setState(() {
        estadoActual = (estadoActual + 1) % estados.length;
      });
    });
  }

  @override
  void dispose() {
    temporizador?.cancel(); // limpiamos el timer al salir
    super.dispose();
  }

  // arma la fecha de hoy en espanol, ej: "Miércoles 28 de mayo"
  String fechaHoy() {
    final ahora = DateTime.now();
    return '${dias[ahora.weekday - 1]} ${ahora.day} de ${meses[ahora.month - 1]}';
  }

  // funcion simple para navegar a la pagina que le pasemos
  void irA(Widget pagina) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pagina),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = estados[estadoActual];

    return Scaffold(
      backgroundColor: colorFondo,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== CAPA 1: imagen de fondo del clima (cambia cada 7s) =====
          // todas tienen el mismo encuadre (bottomCenter + cover) para que
          // solo se note el cambio de clima, no que se mueva la montana.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: Image.asset(
              estado['imagen'],
              key: ValueKey<String>(estado['imagen']),
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),

          // ===== CAPA 2: difuminado de la imagen hacia el caqui =====
          // arriba transparente (se ve el clima) y abajo solido caqui,
          // justo a la altura donde empiezan los botones.
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  colorFondo,
                  colorFondo,
                ],
                stops: [0.0, 0.46, 0.62, 1.0],
              ),
            ),
          ),

          // ===== CAPA 3: contenido =====
          SafeArea(
            child: Column(
              children: [
                // --- barra de identidad ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop,
                          color: Colors.white, size: 26, shadows: sombraTexto),
                      const SizedBox(width: 8),
                      const Text(
                        'Gota',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: sombraTexto,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 18, shadows: sombraTexto),
                      const SizedBox(width: 2),
                      const Text(
                        'Sonora, MX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: sombraTexto,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      fechaHoy(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        shadows: sombraTexto,
                      ),
                    ),
                  ),
                ),

                // --- HERO: circulo con el dato protagonista ---
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: circuloDato(estado),
                ),

                const Spacer(), // empuja los botones hacia abajo

                // --- botones de navegacion (sobre el caqui) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: boton(Icons.bar_chart, 'Gráficos',
                                  () => irA(const Graficos())),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: boton(Icons.chat_bubble_outline, 'Chat',
                                  () => irA(const Chat())),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 96,
                        child: boton(Icons.handshake, 'Socios',
                            () => irA(const Socios())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // circulo (anillo) que rodea los datos centrales: clima, litros y accion
  Widget circuloDato(Map<String, dynamic> estado) {
    return Container(
      key: ValueKey<int>(estadoActual),
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // anillo blanco translucido + leve oscurecido interno para legibilidad
        color: Colors.black.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // clima + temperatura
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(estado['icono'],
                    color: Colors.white, size: 26, shadows: sombraTexto),
                const SizedBox(width: 8),
                Text(
                  '${estado['clima']} · ${estado['temp']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    shadows: sombraTexto,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // EL NUMERO GIGANTE (litros por m²)
            FittedBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    estado['litros'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 86,
                      fontWeight: FontWeight.bold,
                      height: 1,
                      shadows: sombraTexto,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16, left: 4),
                    child: Text(
                      'L/m²',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        shadows: sombraTexto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // accion recomendada
            Text(
              estado['accion'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                shadows: sombraTexto,
              ),
            ),
            const SizedBox(height: 14),
            // sello de confianza (pildora blanca)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: colorBoton, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Datos NASA + sensores',
                    style: TextStyle(
                      color: colorBoton,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  // boton reutilizable: icono arriba + texto, bisel y color slate de la app
  Widget boton(IconData icono, String texto, VoidCallback alPresionar) {
    return ElevatedButton(
      onPressed: alPresionar,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorBoton,
        foregroundColor: Colors.white,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 30),
          const SizedBox(height: 8),
          Text(
            texto,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
