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
else
    error "No se encontró el fichero .env en el directorio actual. Saliendo..."
    exit 1
fi

# Validar que las variables esenciales existan en el .env
if [ -z "$DATA_PATH_HOST" ] || [ -z "$SERVER_INFO_PATH_HOST" ]; then
    error "Faltan DATA_PATH_HOST o SERVER_INFO_PATH_HOST en el .env. Abortando."
    exit 1
fi

# 2. Calcular la carpeta padre solo para DATA_PATH_HOST
# Si DATA_PATH_HOST es '../.odoodock/data', DATA_PARENT_DIR será '../.odoodock'
DATA_PARENT_DIR=$(cd "$(dirname "$DATA_PATH_HOST")" 2>/dev/null && pwd || dirname "$DATA_PATH_HOST")

# Para SERVER_INFO_PATH_HOST usamos directamente el valor válido del .env
INFO_DIR="$SERVER_INFO_PATH_HOST"

# --- ADVERTENCIA Y CONFIRMACIÓN ---
echo -e "${RED}######################################################################${NC}"
echo -e "${RED}  ¡ADVERTENCIA CRÍTICA! VA A REINICIAR Y BORRAR LA INFRAESTRUCTURA   ${NC}"
echo -e "${RED}######################################################################${NC}"
warn "Este script ejecutará las siguientes acciones (requerirá privilegios sudo):"
echo -e "  1. Detener y eliminar todos los contenedores de este proyecto."
echo -e "  2. Eliminar TODOS los volúmenes asociados (¡Pérdida de bases de datos!)."
echo -e "  3. Eliminar elementos huérfanos de Docker."
echo -e "  4. Borrar de raíz mediante SUDO las carpetas del Host:"
echo -e "     - Data Parent Root:  ${CYAN}${DATA_PARENT_DIR}${NC} (Contiene: $DATA_PATH_HOST)"
echo -e "     - Server Info Dir:   ${CYAN}${INFO_DIR}${NC}"
echo -e "  5. Ejecutar 'docker system prune -a --volumes' (Limpieza total del motor Docker)."
echo ""
read -p "¿Está completamente seguro de que desea continuar? (escriba 'SI' en mayúsculas): " USER_CONFIRMATION

if [ "$USER_CONFIRMATION" != "SI" ]; then
    info "Operación cancelada por el usuario. No se ha modificado nada."
    exit 0
fi

# Solicitar credenciales de sudo al inicio para evitar interrupciones a mitad del proceso
info "Solicitando permisos de administrador para limpiar archivos protegidos por el contenedor..."
sudo -v || { error "Se requieren permisos de sudo para continuar. Abortando."; exit 1; }

info "Iniciando el desmantelamiento de la infraestructura..."

# 3. Agrupar dinámicamente los archivos compose del proyecto para asegurar el borrado limpio
COMPOSE_FILES=("-f" "docker-compose.yml")
if [ -f "./[ads]/additional-services-compose.yml" ]; then
    COMPOSE_FILES+=("-f" "./[ads]/additional-services-compose.yml")
fi
if [ -f "docker-compose.debezium.yml" ]; then
    COMPOSE_FILES+=("-f" "docker-compose.debezium.yml")
fi

# 4. Detener servicios, eliminar volúmenes del proyecto y huérfanos
info "Deteniendo servicios y eliminando contenedores, volúmenes locales y huérfanos..."
PROJECT_NAME_PARAM=""
if [ ! -z "$PROJECT_NAME" ]; then
    PROJECT_NAME_PARAM="-p $PROJECT_NAME"
fi

docker compose $PROJECT_NAME_PARAM "${COMPOSE_FILES[@]}" down --volumes --remove-orphans
if [ $? -eq 0 ]; then
    success "Contenedores, redes y volúmenes vinculados al compose eliminados con éxito."
else
    warn "Hubo algún problema o no se encontraron contenedores activos de compose."
fi

# 5. Eliminar carpetas físicas de raíz usando sudo
info "Eliminando directorios del host con privilegios sudo..."

# Eliminar el directorio padre de los datos (.odoodock)
if [ -d "$DATA_PARENT_DIR" ]; then
    warn "Borrando raíz de datos: $DATA_PARENT_DIR"
    sudo rm -rf "$DATA_PARENT_DIR"
    success "Directorio raíz de datos (.odoodock) eliminado por completo."
else
    info "El directorio $DATA_PARENT_DIR no existe, omitiendo."
fi

# Eliminar el directorio de información de servidores (.service-info) tal cual está en el .env
if [ -d "$INFO_DIR" ]; then
    warn "Borrando directorio de información: $INFO_DIR"
    sudo rm -rf "$INFO_DIR"
    success "Directorio de información de servidores eliminado por completo."
else
    info "El directorio $INFO_DIR no existe, omitiendo."
fi

# 6. Prune profundo del sistema Docker
info "Ejecutando docker system prune -a --volumes de forma desatendida..."
docker system prune -a --volumes -f

if [ $? -eq 0 ]; then
    success "Limpieza profunda del demonio de Docker completada."
else
    error "Falló la ejecución del docker system prune."
fi

echo "--------------------------------------------------------"
success "Infraestructura y carpetas raíz (.odoodock / .service-info) eliminadas con éxito."
success "Ya puedes volver a arrancar de cero con ./start-maya.sh"