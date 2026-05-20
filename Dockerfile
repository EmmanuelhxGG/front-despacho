FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
# Limpieza de capas: usamos npm ci para una instalación limpia y determinista
RUN npm ci
COPY . .

# Inyección de variables en tiempo de compilación (CI/CD)
ARG VITE_API_VENTAS_URL
ARG VITE_API_DESPACHOS_URL
ENV VITE_API_VENTAS_URL=$VITE_API_VENTAS_URL
ENV VITE_API_DESPACHOS_URL=$VITE_API_DESPACHOS_URL

RUN npm run build

FROM nginx:alpine
# Copiamos nuestra configuración de Nginx para SPAs
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Ajustar permisos para que el usuario nginx pueda escribir en las carpetas necesarias
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid

# Usar el usuario 'nginx' sin privilegios de root
USER nginx

COPY --from=build --chown=nginx:nginx /app/dist /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
