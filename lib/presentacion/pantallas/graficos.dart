import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // para forzar la orientacion horizontal
import 'package:fl_chart/fl_chart.dart';

// colores de la app (mismos del home para mantener coherencia)
const Color colorBoton = Color(0xFF2F3D52);
const Color colorFondo = Color(0xFFE6E2DC);

// dashboard de metricas. todos los numeros son datos de DEMO:
// inventados, pero optimistas y realistas para una zona arida.
class Graficos extends StatefulWidget {
  const Graficos({super.key});

  @override
  State<Graficos> createState() => _GraficosState();
}

class _GraficosState extends State<Graficos> {
  @override
  void initState() {
    super.initState();
    // al entrar a esta pagina la giramos a horizontal (las graficas se ven mejor)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // al salir devolvemos la app a vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Gráficos'),
        backgroundColor: colorBoton,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ===== fila de 3 tarjetas con numeros grandes (KPIs) =====
              Row(
                children: [
                  Expanded(
                    child: tarjetaKpi(
                      'Agua recomendada hoy',
                      '3 L/m²',
                      Icons.water_drop,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: tarjetaKpi(
                      'Ahorro del mes',
                      '5,800 L',
                      Icons.savings,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: tarjetaKpi(
                      'Humedad actual',
                      '68 %',
                      Icons.grass,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== fila 1 de graficas: riego y ahorro =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: tarjetaGrafica(
                      'Recomendación de riego (últimos 7 días)',
                      graficaRiego(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: tarjetaGrafica(
                      'Agua ahorrada acumulada (este mes)',
                      graficaAhorro(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ===== fila 2 de graficas: humedad y precipitacion =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: tarjetaGrafica(
                      'Humedad del suelo actual',
                      graficaHumedad(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: tarjetaGrafica(
                      'Precipitación esperada (próximos días)',
                      graficaPrecipitacion(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ===== grafica ancha de abajo: temperatura =====
              tarjetaGrafica(
                'Temperatura / evapotranspiración (últimos 7 días)',
                graficaTemperatura(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- tarjetas reutilizables ----------

  // tarjeta con un numero grande (KPI)
  Widget tarjetaKpi(String titulo, String valor, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorBoton,
        // mismo bisel que los botones del home
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: Colors.white70, size: 22),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // caja blanca con titulo arriba y la grafica adentro
  Widget tarjetaGrafica(String titulo, Widget grafica) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: colorBoton,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 200, child: grafica),
        ],
      ),
    );
  }

  // ---------- las 5 graficas (datos de demo) ----------

  // 1) recomendacion de riego: litros/m2 por dia. el sabado llovio (0 L).
  Widget graficaRiego() {
    const dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final puntos = [3.0, 3.0, 5.0, 4.0, 3.0, 0.0, 3.0];
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 6,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 28,
              getTitlesWidget: (valor, meta) => Text(
                valor.toInt().toString(),
                style: const TextStyle(color: colorBoton, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (valor, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  dias[valor.toInt()],
                  style: const TextStyle(color: colorBoton, fontSize: 11),
                ),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < puntos.length; i++) FlSpot(i.toDouble(), puntos[i]),
            ],
            isCurved: true,
            color: colorBoton,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: colorBoton.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  // 2) agua ahorrada acumulada por semana (litros). tendencia al alza = optimista.
  Widget graficaAhorro() {
    const semanas = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
    final valores = [1200.0, 2900.0, 4300.0, 5800.0];
    return BarChart(
      BarChartData(
        maxY: 6500,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2000,
              reservedSize: 40,
              getTitlesWidget: (valor, meta) => Text(
                '${(valor / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(color: colorBoton, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (valor, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  semanas[valor.toInt()],
                  style: const TextStyle(color: colorBoton, fontSize: 11),
                ),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < valores.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valores[i],
                  color: colorBoton,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // 3) humedad del suelo actual: dona/gauge con el % al centro.
  Widget graficaHumedad() {
    const humedad = 68.0; // % saludable para cultivo
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            startDegreeOffset: 270,
            sectionsSpace: 0,
            centerSpaceRadius: 55,
            sections: [
              PieChartSectionData(
                value: humedad,
                color: colorBoton,
                radius: 18,
                showTitle: false,
              ),
              PieChartSectionData(
                value: 100 - humedad,
                color: Colors.black12,
                radius: 18,
                showTitle: false,
              ),
            ],
          ),
        ),
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '68%',
              style: TextStyle(
                color: colorBoton,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'óptima',
              style: TextStyle(color: colorBoton, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  // 4) precipitacion esperada proximos dias (mm). lluvia a mitad de semana.
  Widget graficaPrecipitacion() {
    const dias = ['Hoy', '+1', '+2', '+3', '+4'];
    final mm = [0.0, 2.0, 12.0, 8.0, 0.0];
    return BarChart(
      BarChartData(
        maxY: 16,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 30,
              getTitlesWidget: (valor, meta) => Text(
                '${valor.toInt()}',
                style: const TextStyle(color: colorBoton, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (valor, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  dias[valor.toInt()],
                  style: const TextStyle(color: colorBoton, fontSize: 11),
                ),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < mm.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: mm[i],
                  color: colorBoton,
                  width: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // 5) temperatura de los ultimos 7 dias (°C). sube a mitad de semana (mas calor).
  Widget graficaTemperatura() {
    const dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final temps = [24.0, 26.0, 31.0, 29.0, 25.0, 21.0, 23.0];
    return LineChart(
      LineChartData(
        minY: 15,
        maxY: 35,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 30,
              getTitlesWidget: (valor, meta) => Text(
                '${valor.toInt()}°',
                style: const TextStyle(color: colorBoton, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (valor, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  dias[valor.toInt()],
                  style: const TextStyle(color: colorBoton, fontSize: 11),
                ),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < temps.length; i++) FlSpot(i.toDouble(), temps[i]),
            ],
            isCurved: true,
            color: colorBoton,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: colorBoton.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
