#!/bin/bash

# Colores (manteniendo la estética de tu up.sh)
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

REPOS_FILE="./.repos"
# El nivel superior relativo al directorio donde está este script
TARGET_DIR=".."

# Validar que exista el fichero de repositorios
if [ ! -f "$REPOS_FILE" ]; then
    error "No existe el fichero de configuración $REPOS_FILE. Saliendo..."
    exit 1
fi

info "Iniciando la comprobación y clonado de repositorios..."

# Leer el fichero línea por línea
while IFS='|' read -r repo_path_common method || [ -n "$repo_path_common" ]; do
    # Limpiar espacios en blanco
    repo_path_common=$(echo "$repo_path_common" | xargs)
    method=$(echo "$method" | xargs | tr '[:upper:]' '[:lower:]')

    # Ignorar líneas vacías o comentarios
    if [[ -z "$repo_path_common" || "$repo_path_common" =~ ^# ]]; then
        continue
    fi

    # Extraer de forma automática el nombre de la carpeta (ej: "maya-keycloak-webhook")
    # quitando el ".git" del final si lo tiene
    repo_name=$(basename "$repo_path_common" .git)
    
    # Ruta final en el host donde se guardará el repositorio
    dest_path="$TARGET_DIR/$repo_name"

    # 1. Comprobar si ya existe la carpeta localmente
    if [ -d "$dest_path" ]; then
        warn "El repositorio '$repo_name' ya está clonado en: $dest_path"
        continue
    fi

    # 2. Construir la URL completa según el método elegido
    if [ "$method" == "ssh" ]; then
        git_url="git@github.com:${repo_path_common}"
    elif [ "$method" == "https" ]; then
        git_url="https://github.com/${repo_path_common}"
    else
        error "Método desconocido '$method' para el repo '$repo_path_common'. Usa 'https' o 'ssh'."
        continue
    fi

    # 3. Proceder al clonado en la carpeta superior
    info "Clonando '$repo_name' vía $method en $dest_path..."
    git clone "$git_url" "$dest_path"

    if [ $? -eq 0 ]; then
        success "Repositorio '$repo_name' clonado correctamente."
    else
        error "Falló el clonado de '$repo_name'."
    fi

done < "$REPOS_FILE"

success "Proceso de clonado finalizado."