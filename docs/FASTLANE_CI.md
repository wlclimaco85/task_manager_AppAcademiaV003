# Eu Atleta — GitHub Actions e Fastlane

## Comportamento
- Push/merge na main: compila AAB assinado e envia como rascunho na faixa interna do Google Play.
- Tags v*: também enviam Android para teste interno.
- Actions > Deploy > Run workflow: permite escolher plataforma e lane.
- Produção Android somente ao escolher manualmente lane release.
- iOS somente por execução manual.
- O AAB fica no artefato Eu-Atleta-Android-<execução>-<tentativa>, por 14 dias,
  inclusive quando o upload ao Google falha após concluir a compilação.

## Secrets obrigatórios
GitHub > Settings > Secrets and variables > Actions > Repository secrets:
- ANDROID_KEYSTORE_BASE64: base64 do MESMO keystore de upload cadastrado na Play.
- ANDROID_KEY_ALIAS: alias dessa chave.
- ANDROID_STORE_PASSWORD: senha do keystore.
- ANDROID_KEY_PASSWORD: senha da chave.
- GOOGLE_PLAY_JSON_KEY_BASE64: base64 do JSON da conta de serviço autorizada para o app.

Como o app ainda está em configuração, o padrão de upload interno é draft.
Conclua o rascunho no Play Console para distribuir aos testadores.
Quando o Google permitir releases completas, pode configurar a variável de repositório
PLAY_RELEASE_STATUS=completed em Settings > Secrets and variables > Actions > Variables.

Não coloque as chaves em commits. A chave local android/fastlane/play-store-key.json
foi adicionada ao .gitignore.

## Identidade e versões
Pacote Play: task.manager.flutter.AppAcademia.
Nome de versão: pubspec.yaml (atualmente 1.0.2).
Código CI: 2026101501 + github.run_number * 100 + github.run_attempt.
A base mantém os códigos acima do AAB manual gerado neste chat.
Uma nova tentativa tem outro código; a execução falha se exceder o limite Android.
Se uma execução mais nova já foi enviada, não repita uma execução antiga: use um novo
push ou Run workflow para gerar um número maior que o último publicado.
Aumente a versão visível no pubspec.yaml quando desejar mudar 1.0.2.
Não reutilize códigos já enviados. Se houver upload manual futuro com código maior,
reavalie a base da fórmula antes da próxima execução automática.

## Arquivos e caminhos
O checkout já é a raiz do projeto Flutter, sem subpasta task_manager_AppAcademiaV003.
O workflow usa o Fastfile de fastlane/ na raiz. O Fastfile legado de android/fastlane/
não é usado pelo Actions.
As opções locais de Gradle específicas de Windows são removidas somente no runner Linux.
O app local mantém seu applicationId padrão; o build da loja passa playApplicationId.

## Diagnóstico confirmado
O deploy anterior só disparava com tags v*, e o job excluía push main.
Havia caminhos de trabalho inexistentes, Flutter 3.24 incompatível com o lock,
pacote Play incorreto e versão fixa no Gradle. Os testes também exigiam segredos
sem necessidade.

## Validação e limites
YAML e Ruby validados; Fastlane carregou as lanes sem executar publicação.
Checks de trigger, caminhos, pacote, artefatos e progressão de versão passaram.
O AAB já foi compilado localmente durante o ajuste de permissões.
Não foi executado deploy com a nova automação, nem validada permissão da conta de serviço.
GitHub CLI sem autenticação: histórico de Actions e nomes de secrets não puderam ser consultados.
Estas mudanças precisam chegar à main para ativar o fluxo novo.

## Arquivos a incluir no commit
Além dos workflows, Fastfile, Appfile, pubspec.yaml, Manifest e Gradle ajustados,
inclua android/.gitignore, android/gradlew, android/gradlew.bat e
android/gradle/wrapper/gradle-wrapper.jar. O workflow configura permissão de execução
para o wrapper no runner. Não inclua credenciais nem arquivos de teste pessoais.

