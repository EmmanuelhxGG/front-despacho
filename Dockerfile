# Etapa 1: Construcción (Build)
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Etapa 2: Servidor de producción con Nginx
FROM nginx:alpine
# Copiar configuración personalizada si existe, o usar la de defecto
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Limpiar y copiar archivos construidos
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
