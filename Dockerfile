
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
# Шаг 2: финальный образ (без gcc и мусора)
# ──────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Только runtime-библиотека PostgreSQL (не компилятор)
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Копируем только установленные пакеты из builder
COPY --from=builder /root/.local /root/.local

# Копируем код приложения
COPY app.py models.py requirements.txt ./
COPY templates/ templates/
COPY static/ static/

ENV PATH=/root/.local/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production

EXPOSE 8000

# Gunicorn вместо встроенного Flask-сервера
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]