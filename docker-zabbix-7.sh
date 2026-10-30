#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação Automatizada em Docker - Zabbix Server 7.0 LTS
# Compatibilidade: Ubuntu Server (20.04, 22.04, 24.04, 26.04) e Debian (11, 12, 13)
# ==============================================================================

set -e

# Cores para feedback visual
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# === VERIFICAÇÃO DE PRIVILÉGIOS (ROOT) ===
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ ERRO: Execute este script como root ou utilize 'sudo ./install_zabbix_docker.sh'.${NC}" >&2
    exit 1
fi

# === GARANTINDO O PATH ADMINISTRATIVO ===
if [[ ":$PATH:" != *":/usr/sbin:"* || ":$PATH:" != *":/sbin:"* || ":$PATH:" != *":/usr/local/sbin:"* ]]; then
    export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
fi

# Evita telas interativas durante a instalação de pacotes
export DEBIAN_FRONTEND=noninteractive

# === DETECÇÃO DO SISTEMA OPERACIONAL ===
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" ]]; then
            echo "debian"
        elif [[ "$ID" == "ubuntu" ]]; then
            echo "ubuntu"
        else
            echo "unsupported"
        fi
    else
        echo "unknown"
    fi
}

SYSTEM=$(detect_system)

if [[ "$SYSTEM" == "unsupported" || "$SYSTEM" == "unknown" ]]; then
    echo -e "${RED}❌ Sistema não suportado! Este script funciona apenas em Ubuntu ou Debian.${NC}"
    exit 1
fi

# Obter versão e codinome do sistema
if command -v lsb_release &> /dev/null; then
    OS_VERSION=$(lsb_release -rs)
    OS_CODENAME=$(lsb_release -cs)
else
    OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
    OS_CODENAME=$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '"')
fi

# === VARIÁVEIS DE CONFIGURAÇÃO ===
ZBX_LTS="7.0"
DB_PASSWORD="SenhaSegura123!"
DB_ROOT_PASSWORD="RootSenhaSegura123!"
ZBX_DB="zabbix"
ZBX_USER="zabbix"
PHP_TIMEZONE="America/Sao_Paulo"
INSTALL_DIR="/opt/zabbix-docker"

# === SPLASH BANNER ===
clear
echo -e "${BLUE}"
echo "███████╗ █████╗ ██████╗ ██████╗ ██╗██╗  ██╗"
echo "╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██║╚██╗██╔╝"
echo "  ███╔╝ ███████║██████╔╝██████╔╝██║ ╚███╔╝ "
echo " ███╔╝  ██╔══██║██╔══██╗██╔══██╗██║ ██╔██╗ "
echo "███████╗██║  ██║██████╔╝██████╔╝██║██╔╝ ██╗"
echo "╚══════╝╚═╝  ╚═╝╚═════╝╚═════╝ ╚═╝╚═╝  ╚═╝"
echo -e "${NC}"
echo "========================================================"
echo "   INSTALADOR ZABBIX ${ZBX_LTS} LTS - DOCKER COMPOSE"
echo "   Sistema: ${SYSTEM^^} ${OS_VERSION} (${OS_CODENAME})"
echo "========================================================"
echo ""
sleep 1

# === ETAPA 1: VERIFICAÇÃO E INSTALAÇÃO DE DEPENDÊNCIAS ===
echo -e "${GREEN}🔄 [ETAPA 1/6] Verificando dependências base e fuso horário...${NC}"
DEPS=("wget" "curl" "gpg" "lsb_release")
MISSING_DEPS=0

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS=1
        break
    fi
done

if [ "$MISSING_DEPS" -eq 1 ]; then
    echo -e "${YELLOW}Instalando pacotes base ausentes...${NC}"
    apt update -y
    apt install -y wget curl gnupg2 ca-certificates lsb-release
else
    echo -e "  ✔ Dependências base já estão instaladas."
fi

timedatectl set-timezone "$PHP_TIMEZONE" 2>/dev/null || true
echo -e "  ✔ Fuso horário configurado para ${PHP_TIMEZONE}."

# === ETAPA 2: VERIFICAÇÃO E INSTALAÇÃO DO DOCKER E DOCKER COMPOSE ===
echo -e "\n${GREEN}🐳 [ETAPA 2/6] Verificando instalação do Docker e Docker Compose...${NC}"

if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    echo -e "  ✔ Docker e Docker Compose já estão instalados."
else
    echo -e "${YELLOW}Docker ou Docker Compose não encontrados. Instalando a partir do repositório oficial...${NC}"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${SYSTEM}/gpg" | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${SYSTEM} \
      ${OS_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo -e "  ✔ Docker e Docker Compose instalados com sucesso."
fi

systemctl enable docker &>/dev/null
systemctl start docker

# Adicionar usuário que chamou o sudo ao grupo docker (se aplicável)
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER" 2>/dev/null || true
fi

# === ETAPA 3: GERAÇÃO DO ARQUIVO DOCKER-COMPOSE.YML ===
echo -e "\n${GREEN}📝 [ETAPA 3/6] Criando diretório e gerando docker-compose.yml em ${INSTALL_DIR}...${NC}"
mkdir -p "$INSTALL_DIR"

cat <<EOF > "${INSTALL_DIR}/docker-compose.yml"
services:
  mariadb:
    image: mariadb:10.11
    container_name: zabbix-mariadb
    restart: unless-stopped
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_bin
      - --log-bin-trust-function-creators=1
    environment:
      MYSQL_DATABASE: ${ZBX_DB}
      MYSQL_USER: ${ZBX_USER}
      MYSQL_PASSWORD: "${DB_PASSWORD}"
      MYSQL_ROOT_PASSWORD: "${DB_ROOT_PASSWORD}"
      TZ: ${PHP_TIMEZONE}
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - zabbix-net
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5

  zabbix-server:
    image: zabbix/zabbix-server-mysql:ubuntu-${ZBX_LTS}-latest
    container_name: zabbix-server
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
    environment:
      DB_SERVER_HOST: mariadb
      MYSQL_DATABASE: ${ZBX_DB}
      MYSQL_USER: ${ZBX_USER}
      MYSQL_PASSWORD: "${DB_PASSWORD}"
      TZ: ${PHP_TIMEZONE}
    ports:
      - "10051:10051"
    volumes:
      - zabbix_server_data:/var/lib/zabbix
    networks:
      - zabbix-net

  zabbix-web:
    image: zabbix/zabbix-web-apache-mysql:ubuntu-${ZBX_LTS}-latest
    container_name: zabbix-web
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
      zabbix-server:
        condition: service_started
    environment:
      ZBX_SERVER_HOST: zabbix-server
      DB_SERVER_HOST: mariadb
      MYSQL_DATABASE: ${ZBX_DB}
      MYSQL_USER: ${ZBX_USER}
      MYSQL_PASSWORD: "${DB_PASSWORD}"
      PHP_TZ: ${PHP_TIMEZONE}
      TZ: ${PHP_TIMEZONE}
    ports:
      - "80:8080"
    networks:
      - zabbix-net

  zabbix-agent:
    image: zabbix/zabbix-agent:ubuntu-${ZBX_LTS}-latest
    container_name: zabbix-agent
    restart: unless-stopped
    depends_on:
      - zabbix-server
    environment:
      ZBX_HOSTNAME: "Zabbix server"
      ZBX_SERVER_HOST: zabbix-server
      TZ: ${PHP_TIMEZONE}
    ports:
      - "10050:10050"
    networks:
      - zabbix-net

networks:
  zabbix-net:
    driver: bridge

volumes:
  mariadb_data:
  zabbix_server_data:
EOF

echo -e "  ✔ Arquivo ${INSTALL_DIR}/docker-compose.yml criado com sucesso."

# === ETAPA 4: CONFIGURAÇÃO DE FIREWALL (UFW) ===
echo -e "\n${GREEN}🛡️ [ETAPA 4/6] Verificando regras de Firewall (UFW)...${NC}"
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    ufw allow 80/tcp comment "Zabbix Web UI" &>/dev/null
    ufw allow 10051/tcp comment "Zabbix Server Trapper" &>/dev/null
    ufw allow 10050/tcp comment "Zabbix Agent Local" &>/dev/null
    ufw reload &>/dev/null
    echo -e "  ✔ Portas liberadas no UFW: ${YELLOW}80/tcp (Web), 10051/tcp (Server), 10050/tcp (Agent)${NC}"
else
    echo -e "  ✔ UFW inativo ou não instalado (nenhuma regra adicional necessária)."
fi

# === ETAPA 5: INICIALIZAÇÃO DOS CONTAINERS ===
echo -e "\n${GREEN}🚀 [ETAPA 5/6] Baixando imagens e iniciando os containers...${NC}"
cd "$INSTALL_DIR"
docker compose up -d

# === ETAPA 6: VALIDAÇÃO DOS CONTAINERS E IMPORTAÇÃO DO SCHEMA ===
echo -e "\n${GREEN}⏳ [ETAPA 6/6] Validando integridade dos containers e criação do banco...${NC}"

CONTAINERS=("zabbix-mariadb" "zabbix-server" "zabbix-web" "zabbix-agent")
for container in "${CONTAINERS[@]}"; do
    if [ "$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)" == "true" ]; then
        echo -e "  ✔ Container ${GREEN}${container}${NC}: Em execução"
    else
        echo -e "\n${RED}❌ ERRO CRÍTICO: O container '${container}' não iniciou corretamente.${NC}"
        docker logs "$container" --tail 20
        exit 1
    fi
done

echo -e "${YELLOW}Aguardando o Zabbix Server finalizar a carga do banco de dados (pode levar até 1 minuto)...${NC}"
TIMEOUT=120
ELAPSED=0
while ! docker logs zabbix-server 2>&1 | grep -q "server #0 started \[main process\]"; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo -e "\n${YELLOW}⚠️ Tempo limite de espera atingido. O banco ainda pode estar em fase final de importação.${NC}"
        break
    fi
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    echo -n "."
done
echo -e "\n  ✔ Zabbix Server inicializado e pronto para uso!"

# Obter IP primário da máquina
SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' || hostname -I | awk '{print $1}')

# === CONCLUSÃO E INSTRUÇÕES ===
echo -e "\n${GREEN}========================================================${NC}"
echo -e "${GREEN}   ✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO! ✅${NC}"
echo -e "${GREEN}========================================================${NC}"
echo -e "🌐 ${YELLOW}Interface Web:${NC}     http://${SERVER_IP}"
echo -e "👤 ${YELLOW}Usuário Padrão:${NC}    Admin"
echo -e "🔑 ${YELLOW}Senha Padrão:${NC}      zabbix"
echo -e "--------------------------------------------------------"
echo -e "🛢️ ${YELLOW}Base de Dados:${NC}     ${ZBX_DB}"
echo -e "👤 ${YELLOW}Usuário do Banco:${NC}  ${ZBX_USER}"
echo -e "🔑 ${YELLOW}Senha do Banco:${NC}    ${DB_PASSWORD}"
echo -e "📂 ${YELLOW}Pasta do Projeto:${NC}  ${INSTALL_DIR}"
echo -e "--------------------------------------------------------"
echo -e "🛠️ ${YELLOW}Checar portas ativas:${NC} ss -tulpn | grep -E ':(80|10050|10051)'"
echo -e "🐳 ${YELLOW}Ver containers:${NC}       docker compose -f ${INSTALL_DIR}/docker-compose.yml ps"
echo -e "${GREEN}========================================================${NC}"
