# CLAUDE.md — task_manager_AppAcademiaV003 (App Fitness "Eu Atleta")

> Regras globais da workspace estão em `C:\App_Academia\CLAUDE.md`. Em conflito, o pai prevalece.

## Project

**Flutter — App de fitness/nutrição "Eu Atleta" (academia, treino, dieta e profissionais).**

Domínio confirmado pelos testes e telas: treinos (atividades e histórico), avaliações agendadas,
dieta e **lista de compras da dieta**, catálogo de alimentos (+ sync de importados), **vitrine de
profissionais** (personal/nutri), agenda compartilhada com locais, fotos de atividade, apresentação
"Eu Atleta", recuperação de senha. O botão "Compartilhar" usa o site oficial do Eu Atleta.

**Core Value:** app do atleta/aluno — acompanhar treino e dieta e conectar com profissionais. É um
produto distinto dos apps contábeis, com base de código própria (estrutura `data/src/ui`).

## Stack & Plataformas

- **Flutter/Dart**, Material 3. Package Android: `com.washingtonclimaco.task_manager_appacademia`.
- **Plataformas: android, ios, web**. **Fastlane configurado** (`android/fastlane/`): publicação Play Store.
- Entradas: `main.dart` → `app.dart`. Suíte de testes grande em `test/` (+ `test/e2e/`).

## Arquitetura

- `lib/data/` (constants, controller, models, repository, services, customization, utils),
  `lib/ui/` (screens, widgets, utils), `lib/src/`. Estrutura **diferente** da tríade contábil
  (`data/src/ui` em vez de `web/windows/mobile`).
- **Não faz parte da tríade de replicação contábil.** Mudanças aqui não espelham nos apps contábeis,
  e vice-versa. Compartilha base de código apenas com `task_manager_appDaniel` (fork) — ao mexer em
  algo que os dois têm igual (`lib/src/ensure_visible_when_focused.dart`, `data/customization`),
  avaliar replicar lá.

## Tema (IDENTIDADE PRÓPRIA — NÃO MISTURAR)

- Tema em `lib/data/constants/custom_colors.dart` e `lib/data/customization/` — identidade fitness própria.
- **PROIBIDO** importar/copiar tema de qualquer outro app da workspace.

## UI/UX (OBRIGATÓRIO para mudança de layout)

- Mudança de layout/design DEVE envolver agente de UI/UX (`ui-ux-pro-max` / skill `frontend-design`).
  Correção funcional preserva o layout (menor diff; não reescrever tela inteira).

## Testes & Code Review (OBRIGATÓRIO)

- **Criar e rodar o teste do cenário (`flutter test` focado) antes de concluir.** Suíte inteira (ampla,
  inclui e2e) só antes de push pra `main`. `analyze` é só apoio.
- NUNCA find-replace em massa `const`→`final` (quebra `*.fromEnvironment` em runtime).
- **Push para `main` → code review OBRIGATÓRIO.** Branch base: `desenv`. Encoding UTF-8.
