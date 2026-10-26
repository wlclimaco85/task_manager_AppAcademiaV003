import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/ui/screens/fitness/exame_historico_screen.dart';

void main() {
  test('statusDoUltimo usa o ultimo ponto da serie', () {
    final serie = {
      'pontos': [
        {'status': 'vermelho'},
        {'status': 'verde'},
      ],
    };
    expect(statusDoUltimo(serie), 'verde');
  });

  test('statusDoUltimo devolve null sem pontos ou sem referencia', () {
    expect(statusDoUltimo({'pontos': <Map<String, dynamic>>[]}), isNull);
    expect(statusDoUltimo({'pontos': [{'status': 'sem_referencia'}]}), 'sem_referencia');
  });

  test('cores das opcoes do filtro: Normal verde, Atencao amarelo, Cuidado vermelho', () {
    expect(corDoStatus('verde'), Colors.green.shade500);
    expect(corDoStatus('amarelo'), Colors.amber.shade600);
    expect(corDoStatus('vermelho'), Colors.red.shade400);
    expect(corDoStatus('sem_referencia'), Colors.grey.shade500);
  });
}
