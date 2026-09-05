#!/bin/bash

# Запускаем системный демонизированный Nginx в фоне
echo "==> Starting Nginx reverse proxy..."
nginx -g "daemon on;"

# Запускаем Gunicorn. Обратите внимание: привязываем его к локальному 127.0.0.1:8000.
# Теперь из внешнего мира до Gunicorn никто не достучится — только через Nginx на порту 80.
echo "==> Starting Gunicorn WSGI server..."
exec gunicorn -w 4 -b 127.0.0.1:8000 app:app
