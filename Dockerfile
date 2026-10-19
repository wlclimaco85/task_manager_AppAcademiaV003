# =============================================================================
# Dockerfile — task_manager_AppAcademiaV003 (Meu Treino / Eu Atleta, Flutter Web + Nginx)
# =============================================================================

# ── Stage 1: Build Flutter Web ────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

RUN flutter config --enable-web

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

RUN flutter precache --web

COPY . .

# URLs do backend configuráveis no build. Produção: backend na raiz (sem context-path).
ARG BACKEND_URL=https://appacademia-production-be7e.up.railway.app
ARG BACKEND_CONTEXT_PATH=""
ARG WS_BACKEND_URL=wss://appacademia-production-be7e.up.railway.app
ARG FIREBASE_API_KEY=""
ARG FIREBASE_APP_ID=""
ARG FIREBASE_MESSAGING_SENDER_ID=""
ARG FIREBASE_PROJECT_ID=""
ARG FIREBASE_AUTH_DOMAIN=""
ARG FIREBASE_STORAGE_BUCKET=""
ARG FIREBASE_VAPID_KEY=""
RUN echo "Building with BACKEND_URL=${BACKEND_URL} BACKEND_CONTEXT_PATH=${BACKEND_CONTEXT_PATH} WS_BACKEND_URL=${WS_BACKEND_URL}" && \
    flutter build web --release --no-tree-shake-icons \
        --dart-define=BACKEND_URL=${BACKEND_URL} \
        --dart-define=BACKEND_CONTEXT_PATH=${BACKEND_CONTEXT_PATH} \
        --dart-define=WS_BACKEND_URL=${WS_BACKEND_URL} \
        --dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY} \
        --dart-define=FIREBASE_APP_ID=${FIREBASE_APP_ID} \
        --dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID} \
        --dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID} \
        --dart-define=FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN} \
        --dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET} \
        --dart-define=FIREBASE_VAPID_KEY=${FIREBASE_VAPID_KEY} && \
    echo "Build OK"

# ── Stage 2: Nginx serve ──────────────────────────────────────────────────────
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 8080
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
