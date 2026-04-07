# Pendências para finalizar o Fastlane — task_manager_AppAcademiaV003

## ✅ Já aplicado automaticamente
- `signingConfig` configurado no `android/app/build.gradle.kts`
- Permissões do screengrab no `android/app/src/debug/AndroidManifest.xml`
- `ScreenshotTest.java` criado em `android/app/src/androidTest/`
- Dependências do screengrab adicionadas ao `build.gradle.kts`
- `ios/ci_scripts/ci_post_clone.sh` criado para Xcode Cloud
- `.gitignore` atualizado para proteger keystore e chaves
- Metadados base criados em `fastlane/metadata/`
- GitHub Actions: `deploy.yml` e `tests.yml`
- Fastlane: `Appfile`, `Fastfile`, `Matchfile`, `Deliverfile`, `Screengrabfile`, `Snapfile`, `.env.example`

---

## ⏳ Pendente — requer acesso manual a contas externas

### 1. Bundle ID iOS real
Substitua `com.washingtonclimaco.taskManagerAppacademia` pelo bundle ID real em:
- `fastlane/Appfile`
- `fastlane/Matchfile`

### 2. App Store Connect API Key
1. https://appstoreconnect.apple.com/access/api → criar chave Admin
2. Baixar `.p8` → salvar em `fastlane/AuthKey_SEUKEYID.p8`
3. Preencher `fastlane/.env`

### 3. Match — repositório de certificados iOS
1. Criar repo Git privado para certificados
2. Preencher `MATCH_GIT_URL` e `MATCH_PASSWORD` no `.env`
3. Rodar: `bundle exec fastlane match appstore`

### 4. Keystore Android
```bash
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

### 5. Google Play Service Account
1. Google Play Console → Configuração → Acesso à API → Service Account
2. Baixar JSON → salvar em `fastlane/google-play-key.json`

### 6. GitHub Secrets
| Secret | Como obter |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i android/app/keystore.jks` |
| `ANDROID_KEY_ALIAS` | alias do keystore |
| `ANDROID_STORE_PASSWORD` | senha do keystore |
| `ANDROID_KEY_PASSWORD` | senha da chave |
| `GOOGLE_PLAY_JSON_KEY_BASE64` | `base64 -i fastlane/google-play-key.json` |
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | Key ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | `base64 -i fastlane/AuthKey_*.p8` |
| `APPLE_TEAM_ID` | Team ID Apple Developer |
| `MATCH_GIT_URL` | URL do repo de certificados |
| `MATCH_PASSWORD` | Senha do Match |
| `SLACK_URL` | Webhook Slack (opcional) |

### 7. UI Tests iOS para Screenshots (Xcode)
Criar target `RunnerUITests` no Xcode e adicionar `SnapshotHelper.swift`.

### 8. Testar localmente
```bash
cd task_manager_AppAcademiaV003
bundle install
bundle exec fastlane android beta
bundle exec fastlane ios beta
```
