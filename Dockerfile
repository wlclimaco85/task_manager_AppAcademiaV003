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
RUN echo "Building with BACKEND_URL=${BACKEND_URL} BACKEND_CONTEXT_PATH=${BACKEND_CONTEXT_PATH} WS_BACKEND_URL=${WS_BACKEND_URL}" && \
    flutter build web --release --no-tree-shake-icons \
        --dart-define=BACKEND_URL=${BACKEND_URL} \
        --dart-define=BACKEND_CONTEXT_PATH=${BACKEND_CONTEXT_PATH} \
        --dart-define=WS_BACKEND_URL=${WS_BACKEND_URL} && \
    echo "Build OK"

# ── Stage 2: Nginx serve ──────────────────────────────────────────────────────
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 8080
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
