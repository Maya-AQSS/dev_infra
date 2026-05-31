#!/bin/bash

# Colores (siguiendo la estética de up.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 1. Cargar variables de entorno desde el .env
if [ -f .env ]; then
    set -o allexport && source .env && set +o allexport
fi

# 2. Procesar argumentos (Verificar si se solicita borrar volúmenes)
REMOVE_VOLUMES=false
for arg in "$@"; do
    case $arg in
        -v|--volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
    esac
done

# 3. Agrupar dinámicamente los archivos compose del proyecto para asegurar el apagado completo
COMPOSE_FILES=("-f" "docker-compose.yml")
if [ -f "./[ads]/additional-services-compose.yml" ]; then
    COMPOSE_FILES+=("-f" "./[ads]/additional-services-compose.yml")
fi
if [ -f "docker-compose.debezium.yml" ]; then
    COMPOSE_FILES+=("-f" "docker-compose.debezium.yml")
fi

# 4. Configurar el nombre del proyecto si existe en el .env
PROJECT_NAME_PARAM=""
if [ ! -z "$PROJECT_NAME" ]; then
    PROJECT_NAME_PARAM="-p $PROJECT_NAME"
fi

# 5. Construir el comando final docker compose down
DOWN_CMD="docker compose $PROJECT_NAME_PARAM ${COMPOSE_FILES[@]} down --remove-orphans"

if [ "$REMOVE_VOLUMES" = true ]; then
    warn "¡Atención! Se van a eliminar también todos los volúmenes asociados al proyecto."
    DOWN_CMD="$DOWN_CMD --volumes"
else
    info "Deteniendo la infraestructura (se conservarán los volúmenes de datos)..."
fi

# 6. Ejecutar el comando
eval $DOWN_CMD

if [ $? -eq 0 ]; then
    echo "--------------------------------------------------------"
    if [ "$REMOVE_VOLUMES" = true ]; then
        success "Infraestructura detenida. Contenedores, huérfanos y volúmenes eliminados correctamente."
    else
        success "Infraestructura detenida. Contenedores y huérfanos eliminados. Volúmenes preservados."
    fi
else
    error "Hubo un problema al intentar detener los contenedores de la infraestructura."
    exit 1
fi