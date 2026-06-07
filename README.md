# Дипломный проект по DevOps

## Тема: Система управления пользовательскими запросами в техничекую поддержку.

### Описание: FSSupport — веб-приложение для автоматизации процесса регистрации и обработки обращений пользователей в центр технической поддержки.

### Назначение: система предназначена для операторов технической поддержки и позволяет вести учёт заявок от момента регистрации до закрытия, отслеживать статусы, приоритеты и историю работы по каждому обращению.

## Стек технологий

| Слой | Технологии |
|---|---|
| Приложение | Python, Flask, Gunicorn, PostgreSQL |
| Контейнеризация | Docker, Docker Compose |
| Оркестрация | Kubernetes (AWS EKS) |
| Инфраструктура | Terraform, AWS (VPC, EC2, EKS, S3) |
| Автоматизация | Ansible |
| CI/CD | GitHub Actions |
| Мониторинг | Zabbix 7.0 |
---

## Архитектура решения и сетевой контур

Инфраструктура описана как код (IaC) и развёрнута в регионе Стокгольм (`eu-north-1`) со строгим разделением на три сетевых сегмента по принципу **Zero Trust**:

1. **Публичный сегмент (`public_subnets`)**:
   - **Zabbix-Server / Bastion Host (EC2 `t3.small`, 2 ГБ ОЗУ):** Единая точка входа для мониторинга инфраструктуры. Контейнеризированный стек Zabbix 7.0 LTS (Zabbix Server + Web + MySQL 8.0). Параллельно выполняет роль защищённого бастион-хоста (Jump-сервера). Прямой доступ к приватной зоне из интернета закрыт.

2. **Приватный сегмент (`private_subnets`)**:
   - **App-Database Primary (EC2 `t3.micro`, 1 ГБ ОЗУ):** Нативная СУБД PostgreSQL 16. Без публичного IP. Принимает подключения по порту `5432` исключительно из доверенного CIDR VPC.
   - **App-Database Replica (EC2 `t3.micro`, 1 ГБ ОЗУ):** Резервная реплика PostgreSQL с настроенной Streaming Replication (WAL).
   - **Рабочие ноды AWS EKS (`c7i-flex.large`):** Worker Nodes под управлением Kubernetes, оркеструющие поды Flask-приложения.

3. **Изолированный сегмент (`intra_subnets`)**:
   - Выделен исключительно под сетевые интерфейсы Control Plane управляемого кластера EKS.

---

## Структура проекта

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml                      # Smoke-тесты при PR в develop/main
│       └── deploy.yml                  # Полный деплой при merge в main
├── ansible/
│   ├── group_vars/
│   │   └── all.yml                     # Переменные конфигурации и реквизиты СУБД
│   ├── templates/
│   │   └── zabbix_agent2.conf.j2       # Шаблон конфига Zabbix Agent2
│   ├── ansible.cfg                     # Системная конфигурация Ansible
│   ├── site.yml                        # Главный оркестратор плейбуков
│   ├── deploy-postgre-db.yml           # Установка и настройка PostgreSQL 16
│   ├── deploy-postgres-replication.yml # Настройка Streaming Replication
│   ├── deploy-zabbix.yml               # Развёртывание Zabbix 7.0 в Docker
│   ├── deploy-zabbix-agents.yml        # Установка Zabbix Agent2 на все хосты
│   ├── configure-zabbix-autoregister.yml # Авторегистрация хостов через API
│   ├── docker-compose.zabbix.yml       # Манифест контейнеров Zabbix + MySQL
│   └── inventory.ini.tpl               # Шаблон инвентаря (генерируется Terraform)
├── k8s/
│   ├── deployment.yaml                 # Манифест подов Flask/Gunicorn
│   ├── secret.yaml.tpl                 # Шаблон секретов СУБД
│   └── service.yaml                    # AWS Network Load Balancer (порт 8080)
├── terraform/
│   ├── modules/                        # Модули VPC и EKS
│   ├── main.tf                         # Провайдеры и S3 backend
│   ├── variables.tf                    # Переменные (aws_account_id)
│   ├── outputs.tf                      # IP адреса после apply
│   ├── eks.tf                          # EKS кластер и node groups
│   ├── ec2_database.tf                 # EC2 для PostgreSQL primary + replica
│   └── ec2_zabbix.tf                   # EC2 для Zabbix / Bastion
├── templates/                          # Jinja2 HTML шаблоны
├── static/                             # CSS, JS, изображения
├── app.py                              # Flask приложение и маршруты
├── models.py                           # SQLAlchemy ORM модели
├── Dockerfile                          # Multi-stage сборка образа
├── docker-compose.yml                  # Production конфигурация
├── docker-compose.dev.yml              # Dev конфигурация с hot-reload
└── requirements.txt                    # Python зависимости

---

## Локальная разработка

### Требования

- Docker + Docker Compose
- Git

### Быстрый старт

```bash
# Клонировать репозиторий
git clone https://github.com/kst171/TMS-diplom-2026.git
cd TMS-diplom-2026

# Создать .env файл
cp .env.example .env
# Отредактировать .env при необходимости

# Режим разработки с hot-reload (изменения видны без пересборки)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production режим (Gunicorn, как в AWS)
docker-compose up --build
```

Приложение: `http://localhost:8000`


---

## Ветки Git и CI/CD

### Структура веток

```
main      — production, триггер деплоя в AWS (защищена)
  ↑ PR
develop   — основная ветка разработки
```

### Работа с ветками

```bash
# Начало работы над фичей
git checkout develop
git checkout -b feature/my-feature

# Локальное тестирование
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Коммит и пуш
git add .
git commit -m "feat: описание изменений"
git push origin feature/my-feature

# Создать PR: feature/my-feature → develop
# После прохождения CI → merge
# Создать PR: develop → main → деплой в AWS
```

---

## Развёртывание в AWS

### Требования

- Terraform >= 1.5.0
- AWS CLI с настроенными credentials
- Ansible
- kubectl

### 1. Развёртывание инфраструктуры (IaC)

Выполняется один раз для подготовки облачного контура:

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

Terraform создаёт:
- VPC с публичными, приватными и изолированными подсетями
- EKS кластер (1 нода `c7i-flex.large`)
- EC2 для PostgreSQL primary + replica (`t3.micro`)
- EC2 для Zabbix / Bastion (`t3.small`)
- S3 bucket для хранения terraform state

По окончании автоматически генерируется `ansible/inventory.ini` с актуальными IP адресами.

### 2. Запуск GitOps пайплайна

```bash
git add .
git commit -m "feat: описание"
git push origin develop
# Создать PR develop → main на GitHub
```

### 3. Инспекция состояния в EKS

```bash
# Статус пода (должен быть Running)
kubectl get pods -l app=helpdesk-app

# Получить публичный DNS адрес NLB
kubectl get service helpdesk-service
```

Адрес из столбца `EXTERNAL-IP` открывается в браузере — `http://<EXTERNAL-IP>:8080`

### 4. Подключение к PostgreSQL (для аудита)

```bash
# Подключение через Bastion
ssh -i ~/.ssh/diplom_aws_key -J ubuntu@<PUBLIC_IP_ZABBIX> ubuntu@<DB_PRIVATE_IP>

# Вход в PostgreSQL
sudo -i -u postgres psql
\c fs_support_db
\dt
SELECT * FROM ticket;
```

## Сквозной CI/CD пайплайн

### ЭТАП 1: Конфигурационное управление (Ansible)

1. **Динамический Firewall:** пайплайн определяет IP раннера и временно открывает порт 22 в Security Group через AWS CLI
2. **Zabbix:** Ansible разворачивает Docker и запускает стек мониторинга
3. **PostgreSQL:** через SSH туннель (ProxyCommand via Bastion) устанавливает PostgreSQL 16, создаёт БД и пользователя
4. **Репликация:** настраивает Streaming Replication (WAL) между primary и replica
5. **Мониторинг:** устанавливает Zabbix Agent2 на все EC2, настраивает авторегистрацию через Zabbix API
6. **Закрытие периметра:** отзывает временные правила SSH доступа

### ЭТАП 2: Деплой приложения (Docker + Kubernetes)

1. **Multi-stage сборка:** компиляторы остаются на стадии builder, в финальный образ копируются только пакеты и `libpq5`
2. **Push в Docker Hub:** образ `helpdesk-app:latest`
3. **Генерация секретов:** terraform output → base64 → `k8s/secret.yaml`
4. **Деплой в EKS:** `kubectl apply` манифестов, Bootstrap БД через `db.create_all()`

---

## База данных — Streaming Replication

PostgreSQL 16 с настроенной репликацией:

```
Flask Pod → записывает → Primary PostgreSQL
                               ↓ WAL stream
                         Replica PostgreSQL
                         (синхронная копия)
```
Направление развития: **Patroni** для автоматического failover в production среде.

---

## Мониторинг (Zabbix 7.0)

**Веб интерфейс:** `http://<PUBLIC_IP_ZABBIX>` — логин `Admin` / `zabbix`

Zabbix Agent2 установлен на все EC2 инстансы и автоматически регистрируется в Zabbix Server. Шаблон **Linux by Zabbix agent** собирает:

- CPU utilization, Memory usage
- Disk space, IOPS
- Network traffic
- System uptime, Running processes

---

## GitHub Secrets

Для работы CI/CD необходимо настроить в репозитории:

| Secret | Назначение |
|---|---|
| `AWS_ACCESS_KEY_ID` | Доступ к AWS |
| `AWS_SECRET_ACCESS_KEY` | Доступ к AWS |
| `AWS_ACCOUNT_ID` | ARN в Terraform |
| `SSH_PRIVATE_KEY` | SSH к EC2 инстансам |
| `DOCKERHUB_USERNAME` | Docker Hub |
| `DOCKERHUB_TOKEN` | Docker Hub |
| `DB_PASSWORD` | PostgreSQL пользователь |
| `REPLICATION_PASSWORD` | PostgreSQL репликация |

---

## Автор

Кирилл Тыманович — Дипломный проект TMS DevOps 2026