#!/bin/bash

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 1. Ejecutar el script de clonado
info "Ejecutando clone-repos.sh..."
if [ -f "./clone-repos.sh" ]; then
    bash ./clone-repos.sh
    
    # Comprobar si el script de clonado terminó con errores críticos
    if [ $? -ne 0 ]; then
        error "Hubo un error crítico en clone-repos.sh. Abortando el arranque de contenedores."
        exit 1
    fi
else
    error "No se encontró el script clone-repos.sh en el directorio actual."
    exit 1
fi

echo "--------------------------------------------------------"

# 2. Ejecutar el script up.sh original pasándole todos los argumentos ($@)
info "Ejecutando up.sh para levantar los servicios..."
if [ -f "./up.sh" ]; then
    # Usamos exec para traspasar el proceso actual a up.sh
    exec bash ./up.sh "$@"
else
    error "No se encontró el script up.sh en el directorio actual."
    exit 1
fi