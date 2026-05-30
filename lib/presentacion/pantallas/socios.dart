import 'dart:ui' show ImageFilter; // para el desenfoque de las tarjetas laterales
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// colores de la app (mismos del home para mantener coherencia)
const Color colorBoton = Color(0xFF2F3D52);
const Color colorFondo = Color(0xFFE6E2DC);
const Color azulRey = Color(0xFF2747D6); // azul rey base

// gradiente "metalico" del borde: reflejo claro arriba-izquierda, el slate
// #2F3D52 en medio, sombra profunda abajo y un segundo brillo. da el efecto metal.
const LinearGradient bordeMetalico = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF8A98AE), // brillo claro (reflejo metalico)
    Color(0xFF2F3D52), // slate base de la paleta
    Color(0xFF161D28), // sombra profunda
    Color(0xFF55657E), // segundo reflejo
  ],
  stops: [0.0, 0.40, 0.72, 1.0],
);

// pagina de socios disponibles para conectarse a la app y acrecentar
// los datos y servicios del usuario. son 3 socios en forma de tarjetas
// tipo "planes": se ve una grande al centro y se desliza para la siguiente.
class Socios extends StatefulWidget {
  const Socios({super.key});

  @override
  State<Socios> createState() => _SociosState();
}

class _SociosState extends State<Socios> {
  // el viewportFraction < 1 deja asomar las tarjetas vecinas por los bordes
  final PageController controlador = PageController(viewportFraction: 0.82);
  double pagina = 0; // posicion actual (con decimales mientras se desliza)

  // los datos de los 3 socios (demo)
  final List<Map<String, dynamic>> socios = const [
    {
      'nombre': 'Socio 1',
      'icono': FontAwesomeIcons.helicopter, // representa los drones
      'precio': '\$1,200',
      'beneficios': [
        '5 drones con cámara que miden humedad y salud de tus cultivos',
        'Gráficas exclusivas con los datos del socio y los nuestros',
        'Gráficas avanzadas para usuarios técnicos',
        'Modo oscuro y paletas de color personalizables',
      ],
    },
    {
      'nombre': 'Socio 2',
      'icono': FontAwesomeIcons.towerBroadcast, // representa los sensores de tierra
      'precio': '\$750',
      'beneficios': [
        '15 sensores de tierra que miden humedad y salud de tus cultivos',
        'Gráficas exclusivas con los datos del socio y los nuestros',
        'Gráficas avanzadas para usuarios técnicos',
        'Modo oscuro y paletas de color personalizables',
      ],
    },
    {
      'nombre': 'Socio 3',
      'icono': FontAwesomeIcons.buildingColumns, // representa al gobierno
      'precio': '\$250',
      'beneficios': [
        'Conexión con el gobierno para conseguir agua, levantar quejas y pedir apoyo',
        'Gráficas exclusivas con los datos del socio y los nuestros',
        'Gráficas avanzadas para usuarios técnicos',
        'Modo oscuro y paletas de color personalizables',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    // escuchamos el deslizamiento para animar escala y desenfoque de las tarjetas
    controlador.addListener(() {
      setState(() => pagina = controlador.page ?? 0);
    });
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  // avanza al siguiente socio con una animacion suave
  void irSiguiente() {
    controlador.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // regresa al socio anterior con una animacion suave
  void irAnterior() {
    controlador.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // flecha transparente pero visible para cambiar de socio con un toque
  Widget flecha(IconData icono, VoidCallback alPresionar) {
    return GestureDetector(
      onTap: alPresionar,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          // circulo translucido para que la flecha se vea sin esfuerzo
          color: Colors.white.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icono, color: azulRey.withValues(alpha: 0.85), size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Socios'),
        backgroundColor: colorBoton,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Desliza para ver más socios',
              style: TextStyle(color: colorBoton, fontSize: 13),
            ),
            // ===== carrusel de tarjetas =====
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: controlador,
                    itemCount: socios.length,
                    itemBuilder: (context, index) {
                      // que tan lejos esta esta tarjeta del centro (0 = centrada)
                      final distancia = (index - pagina).abs().clamp(0.0, 1.0);
                      // central grande; laterales un poco mas chicas y desenfocadas
                      final escala = 1 - distancia * 0.12;
                      final desenfoque = distancia * 3.0;

                      Widget tarjeta = tarjetaSocio(socios[index]);

                      // solo aplicamos blur si la tarjeta NO esta centrada
                      if (desenfoque > 0.05) {
                        tarjeta = ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: desenfoque,
                            sigmaY: desenfoque,
                            tileMode: TileMode.decal,
                          ),
                          child: tarjeta,
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 24),
                        child: Transform.scale(scale: escala, child: tarjeta),
                      );
                    },
                  ),
                  // flecha IZQUIERDA: solo si hay un socio anterior
                  if (pagina.round() > 0)
                    Positioned(
                      left: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: flecha(Icons.chevron_left, irAnterior),
                      ),
                    ),
                  // flecha DERECHA: solo si hay un socio siguiente
                  if (pagina.round() < socios.length - 1)
                    Positioned(
                      right: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: flecha(Icons.chevron_right, irSiguiente),
                      ),
                    ),
                ],
              ),
            ),
            // ===== puntitos indicadores (cual tarjeta se ve) =====
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < socios.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: pagina.round() == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: pagina.round() == i ? azulRey : colorBoton.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
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

  // una tarjeta de socio (estilo plan tipo Surfshark)
  Widget tarjetaSocio(Map<String, dynamic> socio) {
    final List beneficios = socio['beneficios'];
    // CAPA EXTERNA: hace de "borde" con el gradiente metalico.
    return Container(
      decoration: ShapeDecoration(
        gradient: bordeMetalico, // borde azul rey con brillo metalico
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // sombra slate suave para dar profundidad
        shadows: [
          BoxShadow(
            color: colorBoton.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3), // grosor del borde metalico
      // CAPA INTERNA: el contenido blanco de la tarjeta.
      child: Container(
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        // scroll interno: si el contenido es mas alto que la tarjeta, se desliza
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // nombre del socio
          Text(
            socio['nombre'],
            style: const TextStyle(
              color: colorBoton,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          // icono distintivo del socio (dron / sensor / gobierno)
          FaIcon(socio['icono'], color: colorBoton, size: 64),
          const SizedBox(height: 24),
          // precio
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                socio['precio'],
                style: const TextStyle(
                  color: colorBoton,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  'MXN / mes',
                  style: TextStyle(color: colorBoton, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: azulRey, thickness: 1),
          const SizedBox(height: 12),
          // lista de beneficios con palomita
          for (final b in beneficios)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: colorBoton, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: colorBoton,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // boton de accion (demo, sin accion real por ahora)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBoton,
                foregroundColor: Colors.white,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Contratar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
