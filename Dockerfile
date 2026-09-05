# ──────────────────────────────────────────
# Шаг 1: установка зависимостей
# ──────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ──────────────────────────────────────────
# Шаг 2: финальный образ (со встроенным Nginx)
# ──────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Устанавливаем runtime-библиотеку PostgreSQL И веб-сервер Nginx
# Сразу удаляем дефолтный конфиг Nginx, чтобы он не конфликтовал с нашим
RUN apt-get update && apt-get install -y \
    libpq5 \
    nginx \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

# Копируем только установленные пакеты из builder
COPY --from=builder /root/.local /root/.local

# Копируем код приложения и статические файлы
COPY app.py models.py requirements.txt ./
COPY templates/ templates/
COPY static/ static/
# КРИТИЧНО: Явно копируем папку миграций во второй (финальный) этап сборки
COPY migrations/ migrations/

# Копируем конфигурационный файл Nginx в системную директорию
COPY nginx.conf /etc/nginx/sites-enabled/default

# Копируем и даем права на запуск скрипту-оркестратору служб
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

ENV PATH=/root/.local/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production

# ВАЖНО: Теперь контейнер слушает стандартный HTTP-порт 80 (который держит Nginx)
EXPOSE 80

# Скрипт запустит Nginx на порту 80 и Gunicorn на 127.0.0.1:8000
CMD ["./entrypoint.sh"]
