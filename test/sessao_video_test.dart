import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/fitness/sessao_treino_registro_model.dart';
import 'package:task_manager_flutter/data/services/fitness_offline_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('observacao e video permanecem no historico', () async {
    SharedPreferences.setMockInitialValues({});
    const sessao = SessaoTreinoRegistroModel(id: 'video', treinoId: 'treino',
      divisaoLetra: 'A', divisaoNome: 'Treino A', alunoId: 'aluno',
      dataHoraInicio: '2026-10-14T15:00:00', dataHoraFim: '2026-10-14T15:30:00',
      duracaoSegundos: 1800, exerciciosExecutados: [],
      feedbackAluno: 'Senti melhora', videoUrl: 'https://youtu.be/HpWWreyaBN0');
    await FitnessOfflineRepository().registrarSessaoConcluida(sessao);
    final salvo = (await FitnessOfflineRepository().getSessoesConcluidas(alunoId: 'aluno')).single;
    expect(salvo.toMap(), sessao.toMap());
    final antigo = sessao.toMap()..remove('videoUrl');
    expect(SessaoTreinoRegistroModel.fromMap(antigo).videoUrl, isNull);
  });
}
