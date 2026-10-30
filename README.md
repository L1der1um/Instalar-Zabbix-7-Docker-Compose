# 🚀 Zabbix Docker Auto Installer

<p align="center">

![Bash](https://img.shields.io/badge/Bash-Script-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Compatible-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Debian](https://img.shields.io/badge/Debian-Supported-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-Supported-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Zabbix](https://img.shields.io/badge/Zabbix-7.0_LTS-D40000?style=for-the-badge&logo=zabbix&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-Database-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

</p>

Script desenvolvido para realizar a **implantação totalmente automatizada do Zabbix 7.0 LTS via Docker Compose**, incluindo instalação do Docker, banco de dados, frontend web, servidor, agente e configuração inicial do ambiente.

O objetivo é disponibilizar uma instalação em containers **segura, rápida, isolada e padronizada**, eliminando praticamente toda a configuração manual necessária.

---

# 📦 Este repositório

Este repositório contém a documentação e o instalador automatizado para o Zabbix 7.0 LTS em containers.

| Arquivo | Descrição |
|---------|---------|
| ✅ README.md | Documentação completa do projeto |
| ✅ docker-zabbix-7.sh | Instalador automatizado Zabbix 7.0 LTS (Docker) |

O script utiliza exclusivamente os repositórios oficiais do Docker e as imagens oficiais do Zabbix 7.0 LTS.

---

# ✨ Funcionalidades

- 🚀 Implantação completa do Zabbix 7.0 LTS em containers
- 🐳 Instalação automática do Docker e Docker Compose
- 🐧 Compatível com Debian e Ubuntu
- 🔍 Detecção automática da distribuição
- 📦 Instalação automática das dependências base
- 📝 Geração automática do arquivo `docker-compose.yml`
- 🛢️ Subida automática do container MariaDB 10.11
- 💾 Criação e importação automática do banco de dados
- 👤 Criação automática do usuário do banco
- 📊 Inicialização do container Zabbix Server
- 🌐 Inicialização do container Frontend Web (Apache + PHP)
- 🤖 Inicialização do container Zabbix Agent
- 🔥 Configuração automática do firewall (UFW)
- ⏰ Configuração automática do Timezone
- 🎨 Interface amigável com mensagens coloridas

---

# 🖥️ Sistemas suportados

O script detecta automaticamente o sistema operacional.

Atualmente suporta:

- Debian 11, 12 e 13
- Ubuntu 20.04
- Ubuntu 22.04
- Ubuntu 24.04
- Ubuntu 26.04

---

# 📦 Componentes instalados

O script instala e provisiona automaticamente:

- Docker Engine (`docker-ce`)
- Docker Compose Plugin
- Container Zabbix Server 7.0 LTS
- Container Zabbix Frontend (Apache + PHP)
- Container Zabbix Agent 7.0 LTS
- Container MariaDB 10.11
- Rede isolada Docker (`zabbix-net`)
- Volumes persistentes de dados

---

# 🛢️ Banco de dados

O script provisiona automaticamente um container dedicado com:

## Debian e Ubuntu

- MariaDB 10.11 Server (Container oficial)

Após a inicialização do container são configurados automaticamente:

- Conjunto de caracteres `utf8mb4` e colação `utf8mb4_bin`
- Banco de dados `zabbix`
- Usuário e permissões
- Parâmetro `log-bin-trust-function-creators=1`
- Importação automática do schema oficial pelo Zabbix Server

---

# ⚙️ Como funciona

A instalação é dividida em seis etapas.

---

## 1️⃣ Verificação de dependências e sistema

- verificação de pacotes base (`wget`, `curl`, `gpg`, `lsb_release`)
- instalação automática apenas das dependências ausentes
- configuração do timezone no sistema operacional

---

## 2️⃣ Instalação do Docker

Caso não estejam presentes no servidor, o script instala automaticamente:

- Chave GPG e repositório oficial do Docker
- Docker Engine (`docker-ce` e `docker-ce-cli`)
- Containerd e Docker Compose Plugin

---

## 3️⃣ Geração do Docker Compose

O script cria o diretório `/opt/zabbix-docker` e gera o arquivo `docker-compose.yml` configurando:

- container do banco de dados com *healthcheck*;
- credenciais e variáveis de ambiente;
- fuso horário do PHP;
- mapeamento de portas e volumes persistentes.

```text
PHP_TZ = America/Sao_Paulo
```

---

## 4️⃣ Configuração do Firewall

Nesta etapa são realizadas:

- verificação de status do firewall UFW;
- liberação da porta 80/tcp (Frontend Web);
- liberação da porta 10051/tcp (Zabbix Server);
- liberação da porta 10050/tcp (Zabbix Agent).

---

## 5️⃣ Inicialização dos Containers

São baixadas as imagens oficiais e iniciados em segundo plano:

- `zabbix-mariadb`
- `zabbix-server`
- `zabbix-web`
- `zabbix-agent`

---

## 6️⃣ Importação do banco e validação

Ao iniciar o container `zabbix-server`, ele importa automaticamente o schema oficial do Zabbix no MariaDB.

O script monitora os logs em tempo real e aguarda a inicialização completa do processo principal antes de exibir a tela de conclusão.

Dependendo da conexão e do hardware do servidor, esse processo leva entre **1 e 3 minutos**.

---

# 🔄 Fluxo da instalação

```text
Detectar Sistema
        │
        ▼
Verificar Dependências e Timezone
        │
        ▼
Instalar Docker e Docker Compose
        │
        ▼
Gerar docker-compose.yml
        │
        ▼
Configurar Firewall (UFW)
        │
        ▼
Baixar Imagens Oficiais
        │
        ▼
Subir Containers
        │
        ▼
Importar Schema Automaticamente
        │
        ▼
Validar Inicialização dos Serviços
        │
        ▼
Exibir Credenciais
```

---

# ▶️ Execução

Conceda permissão:

```bash
chmod +x docker-zabbix-7.sh
```

Execute:

```bash
sudo ./docker-zabbix-7.sh
```

---

# 🌐 Informações de acesso

Após a instalação (acesso direto na raiz, sem `/zabbix`):

```text
URL

http://IP_DO_SERVIDOR
```

Credenciais padrão:

```text
Usuário

Admin
```

```text
Senha

zabbix
```

---

# 🛢️ Banco de dados

São criados automaticamente:

| Item | Valor |
|------|------|
| Host Interno | mariadb |
| Banco | zabbix |
| Usuário | zabbix |
| Senha | SenhaSegura123! |
| Senha Root | RootSenhaSegura123! |

Após a instalação recomenda-se alterar todas as senhas padrão.

---

# 🔥 Firewall

Caso o **UFW** esteja ativo serão liberadas automaticamente as portas:

| Porta | Serviço |
|--------|----------|
| 80 | Frontend Web |
| 10050 | Zabbix Agent |
| 10051 | Zabbix Server |

---

# 📋 Comandos úteis

Verificar status dos containers:

```bash
docker compose -f /opt/zabbix-docker/docker-compose.yml ps
```

Reiniciar os containers:

```bash
docker compose -f /opt/zabbix-docker/docker-compose.yml restart
```

Logs do Zabbix Server:

```bash
docker compose -f /opt/zabbix-docker/docker-compose.yml logs -f zabbix-server
```

---

# 📌 Pré-requisitos

- Debian ou Ubuntu
- Conexão com a Internet
- Permissão de root ou sudo
- Portas 80, 10050 e 10051 livres

---

# ✅ Benefícios

- Instalação limpa em poucos minutos
- Processo totalmente automatizado
- Isolamento completo em containers Docker
- Compatível com a versão 7.0 LTS
- Configuração padronizada
- Utiliza apenas imagens e repositórios oficiais
- Criação e importação automática do banco
- Configuração automática do PHP e Apache via container
- Configuração automática do firewall
- Fácil manutenção, backup e atualização

---

# 🛠️ Tecnologias utilizadas

- Bash
- Docker
- Docker Compose
- Zabbix Server 7.0 LTS
- Zabbix Agent 7.0 LTS
- Apache
- PHP
- MariaDB 10.11
- UFW
- APT

---

# 📄 Licença

Este projeto está licenciado sob a licença **MIT**.

Você pode utilizar, modificar e distribuir este projeto livremente, desde que mantenha os créditos e o texto da licença.

---

# 👨‍💻 Autor

Desenvolvido para automatizar a implantação do **Zabbix 7.0 LTS em Docker** em ambientes Debian e Ubuntu, padronizando instalações, reduzindo erros de configuração e acelerando a disponibilização de ambientes de monitoramento para laboratórios e produção.
