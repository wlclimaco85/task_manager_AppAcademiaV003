# AppAcademia V003 - Mapa Base Fitness 360

Data: 2026-06-18

## Regra de escopo

`task_manager_AppAcademiaV003` e um aplicativo separado. As entregas deste
roadmap devem alterar somente o mobile V003 quando forem de interface mobile.
O backend segue compartilhado em `AppAcademia`. As telas web e Windows do
produto contabil continuam em `task_manager_flutter` e nao devem receber
replicacao automatica deste roadmap.

## Base mobile existente

- Entrada principal: `lib/ui/screens/bottom_navbar_screen.dart`.
- Hub fitness inicial: `_FitnessHubScreen`, com atalhos por permissao.
- Navegacao inferior atual: Inicio, Treinos, Alunos, Atividade, Metas e Mais.
- Workspace do personal/alunos: `lib/ui/screens/personal_workspace_screen.dart`.
- Telas metricas placeholder: `lib/ui/screens/fitness_personal_screens.dart`.
- Grids dinamicos fitness ja conectados ao backend compartilhado:
  - `AlimentoScreenDynamic`
  - `ObjetivoScreenDynamic`
  - `AvaliacaoFisicaScreenDynamic`
  - `GrupoMuscularScreenDynamic`
  - `ModalidadeScreenDynamic`
- Fluxos existentes relacionados a saude:
  - dieta: `dieta_screen.dart`, `dieta_add.dart`, `dieta_list.dart`
  - medicamentos: `medicamento_screen.dart`, `medicamento_add.dart`
  - suplementos: `suplemento_screen.dart`, `suplemento_add.dart`
  - exames: `exames_screen.dart`, `exames_add.dart`
  - ponto, chamados, chat, GED e financeiro herdados do app base.

## APIs ja mapeadas no app

Arquivo: `lib/data/utils/api_links.dart`.

- Login e cadastro: `/rest/auth/login`, `/rest/auth/registrar-aluno`,
  `/rest/auth/registrar-personal`, `/rest/auth/academias-disponiveis`,
  `/rest/auth/personais-disponiveis`.
- Fitness/cadastros: `/api/alimentos`, `/api/dietas`, `/api/exames`,
  `/api/exercicios`, `/api/grupos-musculares`, `/api/medicamentos`,
  `/api/modalidades`, `/api/objetivos`, `/api/personais`, `/api/planos`,
  `/api/suplementos`.
- Dinamico: `/api/telas/{nome}` com parametros de tenant.

## Lacunas por fase

### Fase 1 - Home Saude do Aluno

Trocar os valores estaticos do hub por dados reais ou agregados do backend:
resumo diario, metas, progresso semanal e alertas de habitos.

### Fase 2 - Atividade e Treino

Persistir sessoes de treino/atividade, historico por aluno e detalhe da sessao.
Hoje as telas de atividade/treino sao principalmente placeholders visuais.

### Fase 3 - Corpo, Peso e Exames

Unificar peso, IMC, medidas, composicao corporal e exames em uma linha do tempo
do aluno. Ja existem exames e avaliacao fisica como pontos de partida.

### Fase 4 - Sono, Check-in e Habitos

Criar registros de sono, check-in diario, agua, medicamento, suplemento e
lembretes. Hoje `SonoScreen` e cards de habito sao mockados.

### Fase 5 - Integracoes de Saude

Fazer spike tecnico de Health Connect, Apple Health e importacao manual,
incluindo consentimento, revogacao e armazenamento minimo necessario.

### Fase 6 - Gamificacao e Comunidade

Planejar ranking opcional, conquistas, conteudos e comunidade/mural com
controle de privacidade por academia/aluno.

## Riscos

- Nao misturar regras do app contabil web/windows com o V003 mobile.
- Nao duplicar regra de negocio no Flutter quando o backend compartilhado deve
centralizar validacao, tenant e persistencia.
- Recursos de saude exigem consentimento explicito e cuidado com dados sensiveis.
- Integracoes Health Connect/Apple Health precisam de spike antes de compromisso
de prazo.
