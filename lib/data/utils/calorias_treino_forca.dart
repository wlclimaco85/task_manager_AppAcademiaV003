/// Estima o gasto energético de musculação a partir do MET, duração, peso e
/// percepção de esforço informada pelo aluno.
///
/// Fórmula: kcal = MET × 3,5 × peso (kg) / 200 × minutos.
double metTreinoForcaPorRpe(int rpe) {
  final esforco = rpe.clamp(1, 10);
  if (esforco <= 4) return 3.5;
  if (esforco <= 7) return 5.0;
  return 6.0;
}

String intensidadeTreinoForca(int rpe) {
  final esforco = rpe.clamp(1, 10);
  if (esforco <= 4) return 'Leve';
  if (esforco <= 7) return 'Moderada';
  return 'Alta';
}

int? calcularCaloriasTreinoForca({
  required int minutos,
  required int rpe,
  required double? pesoKg,
}) {
  if (minutos <= 0 || pesoKg == null || pesoKg <= 0) return null;
  final met = metTreinoForcaPorRpe(rpe);
  return (met * 3.5 * pesoKg / 200 * minutos).round();
}
