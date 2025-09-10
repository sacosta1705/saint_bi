import 'dart:math';

/// Calcula un intervalo "redondo" y eficiente para las etiquetas de un eje de gráfico.
///
/// El objetivo es generar entre 4 y 6 divisiones principales en la cuadrícula,
/// sin importar la escala del valor máximo.
double getEfficientInterval(double maxValue) {
  if (maxValue <= 0) return 1;

  // Se busca un intervalo que genere entre 4 y 6 líneas de cuadrícula
  final double roughInterval = maxValue / 5;

  // Se calcula la potencia de 10 más cercana al intervalo aproximado.
  // Ej: si roughInterval es 1800, la magnitud es 1000.
  // --- CORRECCIÓN AQUÍ ---
  final double magnitude = pow(
    10,
    (log(roughInterval) / log(10)).floor(),
  ).toDouble();

  // Se normaliza el intervalo dividiéndolo por su magnitud.
  // Ej: 1800 / 1000 = 1.8
  final double residual = roughInterval / magnitude;

  double niceInterval;
  // Se redondea el residual a un número "limpio" (1, 2, 5, o 10).
  if (residual > 5) {
    niceInterval = 10 * magnitude; // Ej: si es 6.8 -> 10 * 1000 = 10000
  } else if (residual > 2) {
    niceInterval = 5 * magnitude; // Ej: si es 3.1 -> 5 * 1000 = 5000
  } else if (residual > 1) {
    niceInterval = 2 * magnitude; // Ej: si es 1.8 -> 2 * 1000 = 2000
  } else {
    niceInterval = magnitude; // Ej: si es 0.9 -> 1 * 1000 = 1000
  }

  return niceInterval > 0 ? niceInterval : 1;
}
