# React + Vite

Frontend Innovatech Chile — Despachos
Descripción
Aplicación web desarrollada en React + Vite que consume las APIs de Ventas y Despachos desplegadas en AWS EC2. Contenedorizada con Docker y desplegada automáticamente mediante CI/CD con GitHub Actions.

Tecnologías utilizadas

React + Vite
Nginx Alpine (servidor de producción)
Docker (multi-stage build)
GitHub Actions (CI/CD)
Amazon ECR (registro de imágenes)
Amazon EC2 (despliegue)
AWS SSM (despliegue remoto)


Estructura del repositorio
front_despacho/
├── .github/
│   └── workflows/
│       └── deploy.yml        # Pipeline CI/CD
├── src/                      # Código fuente React
├── public/                   # Archivos estáticos
├── Dockerfile                # Imagen Docker multi-stage
├── docker-compose.yml        # Orquestación local
├── package.json
└── README.md

Contenedorización (IE1)
Dockerfile — Multi-stage Build
El Dockerfile implementa una estrategia de construcción en dos etapas:
Stage 1 — Build:

Imagen base: node:18-alpine (ligera)
Instala dependencias con npm ci (instalación limpia, sin caché)
Inyecta variables de entorno mediante ARG/ENV para las URLs del backend
Compila el proyecto con npm run build

Stage 2 — Producción:

Imagen base: nginx:alpine (ligera, solo para servir archivos estáticos)
Usuario no-root: se ejecuta como usuario nginx para cumplir el principio de mínimo privilegio
Copia únicamente los archivos compilados del stage anterior (/app/dist)
Expone el puerto 8080

Beneficios del multi-stage:

La imagen final no contiene Node.js ni dependencias de desarrollo
Reduce el tamaño de la imagen significativamente
Minimiza la superficie de ataque (seguridad)

docker-compose.yml
Permite levantar el frontend de forma independiente en entorno local:
yamlservices:
  frontend:
    build:
      context: .
      args:
        VITE_API_VENTAS_URL: ${VITE_API_VENTAS_URL}
        VITE_API_DESPACHOS_URL: ${VITE_API_DESPACHOS_URL}
    ports:
      - "80:8080"

Variables de entorno
VariableDescripciónVITE_API_VENTAS_URLURL de la API de Ventas (ej: http://IP_BACKEND:8081)VITE_API_DESPACHOS_URLURL de la API de Despachos (ej: http://IP_BACKEND:8082)
Las variables se inyectan en tiempo de compilación mediante build-args en el pipeline, eliminando IPs hardcodeadas del código fuente.

Pipeline CI/CD (IE3)
Flujo completo
Push a rama deploy
       ↓
Checkout del código
       ↓
Configurar credenciales AWS
       ↓
Login en Amazon ECR
       ↓
Build imagen Docker (con inyección de variables)
       ↓
Push imagen a ECR con tag :latest
       ↓
Deploy en EC2 vía AWS SSM
       ↓
docker pull + docker run en EC2 Frontend
Activación
El pipeline se activa únicamente con push a la rama deploy:
yamlon:
  push:
    branches: [ "deploy" ]
GitHub Secrets configurados
SecretDescripciónAWS_ACCESS_KEY_IDCredencial AWS (se renueva cada 4h en Academy)AWS_SECRET_ACCESS_KEYCredencial AWS (se renueva cada 4h en Academy)AWS_SESSION_TOKENToken de sesión AWS (se renueva cada 4h en Academy)AWS_REGIONRegión AWS (us-east-1)ECR_REGISTRYURL base del registro ECRECR_REPO_URL_FRONTENDURL completa del repositorio ECR del frontendEC2_FRONTEND_INSTANCE_IDID de la instancia EC2 del frontend (i-xxxxx)VITE_API_VENTAS_URLURL de la API de Ventas en producciónVITE_API_DESPACHOS_URLURL de la API de Despachos en producción

Infraestructura AWS (IE4)
Instancia EC2 Frontend

Tipo: t2.micro — Amazon Linux 2023
Subred: Pública (accesible desde internet)
Puerto expuesto: 80 (HTTP)
Security Group: permite tráfico HTTP (0.0.0.0/0) en puerto 80

Comunicación Frontend → Backend
El frontend consume las APIs del backend mediante variables de entorno inyectadas en compilación:

VITE_API_VENTAS_URL → http://IP_BACKEND:8081
VITE_API_DESPACHOS_URL → http://IP_BACKEND:8082

La comunicación respeta las políticas del Security Group del backend, que solo permite tráfico desde el Security Group del frontend.

Ejecución local
bash# Clonar el repositorio
git clone https://github.com/TU_USUARIO/front_despacho.git
cd front_despacho

# Crear archivo .env
echo "VITE_API_VENTAS_URL=http://localhost:8081" > .env
echo "VITE_API_DESPACHOS_URL=http://localhost:8082" >> .env

# Levantar con docker-compose
docker-compose up -d
Acceder en: http://localhost

Principios DevOps aplicados (IE8)
PrácticaImplementaciónContenedorizaciónDocker multi-stage, usuario no-root, imagen Alpine ligeraGestión de entornosVariables de entorno via ARG/ENV, sin IPs hardcodeadasCI/CD automatizadoGitHub Actions con trigger en rama deployControl de versionesGit con rama deploy para producciónSeguridadGitHub Secrets para credenciales, usuario no-root en contenedorTrazabilidadImágenes etiquetadas con :latest en ECR, logs en GitHub Actions

Justificación técnica
¿Por qué multi-stage build?
Separa el entorno de compilación (Node.js + dependencias de desarrollo) del artefacto final de producción (archivos estáticos). La imagen final solo contiene Nginx y los archivos HTML/CSS/JS compilados, reduciendo el tamaño y la superficie de ataque.
¿Por qué usuario no-root?
El principio de mínimo privilegio reduce el impacto de posibles vulnerabilidades. Si el contenedor es comprometido, el atacante no tiene privilegios de administrador sobre el host.
¿Por qué Amazon ECR?
ECR está integrado nativamente con IAM y EC2, permitiendo autenticación segura sin exponer credenciales. Es el registro recomendado para proyectos en AWS Academy.
¿Por qué SSM en lugar de SSH?
AWS SSM no requiere abrir el puerto 22 ni gestionar llaves SSH en el pipeline. Es más seguro y no depende de IPs públicas que cambian con cada reinicio del laboratorio.