# Push no navegador e no celular

O app registra o navegador ou celular autenticado em `POST /api/device-token`.
Os eventos da agenda são gravados como alertas e enviados pelo Firebase Cloud
Messaging (FCM) na criação, alteração, cancelamento e no horário do lembrete.

## Configuração pública do aplicativo

Informe estes valores públicos do projeto Firebase no build do Flutter:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID` (`FIREBASE_ANDROID_APP_ID` e `FIREBASE_IOS_APP_ID` no GitHub)
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN` (web)
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_VAPID_KEY` (web push)

O `Dockerfile` repassa os argumentos automaticamente ao build web. As lanes do
Fastlane fazem o mesmo para Android e iOS. Sem esses valores, o app continua
funcionando e apenas deixa o registro de push desativado.

## Credencial privada do backend

Configure no ambiente do backend:

- `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64`: JSON da service account codificado em Base64; ou
- `FIREBASE_SERVICE_ACCOUNT_JSON`: o JSON completo;
- `FIREBASE_PROJECT_ID`: opcional quando `project_id` já existe no JSON.

Essa credencial é privada e nunca deve entrar no app, no repositório ou em um
`--dart-define`.
