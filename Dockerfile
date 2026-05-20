FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

# Inyección de variables en tiempo de compilación (CI/CD)
# En producción, pasa estos valores via build args desde GitHub Actions
ARG VITE_API_VENTAS_URL=http://ventas-api:8080/api/v1/ventas
ARG VITE_API_DESPACHOS_URL=http://despachos-api:8081/api/v1/despachos
ENV VITE_API_VENTAS_URL=$VITE_API_VENTAS_URL
ENV VITE_API_DESPACHOS_URL=$VITE_API_DESPACHOS_URL

RUN npm run build

FROM nginx:alpine
# Copiamos nuestra configuración de Nginx personalizada para React (SPA)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Configurar Nginx para servir SPA de React y hacer proxy a los backends
RUN echo 'server {
    listen 8080;
    server_name _;
    
    root /usr/share/nginx/html;
    
    # SPA - Redirigir todas las rutas a index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Proxy al API de Ventas
    location /api/v1/ventas {
        proxy_pass http://ventas-api:8080/api/v1/ventas;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Proxy al API de Despachos
    location /api/v1/despachos {
        proxy_pass http://despachos-api:8081/api/v1/despachos;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Caché para archivos estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}' > /etc/nginx/conf.d/default.conf

# Ajustar permisos para que el usuario nginx pueda escribir en las carpetas necesarias
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid

# Usar el usuario 'nginx' sin privilegios de root
USER nginx

COPY --from=build --chown=nginx:nginx /app/dist /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
