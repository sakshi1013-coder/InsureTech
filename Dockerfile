# Multi-stage Docker build for InsureX Flutter Web on Render
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --no-tree-shake-icons

# Stage 2: Serve using NGINX
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# SPA fallback configuration to handle direct route refresh
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
