#!/bin/bash
# Аварийное восстановление сетевого моста
# Запускайте, если что-то пошло не так с сетью

echo "=== Аварийное восстановление сети ==="

# Завершить любые зависшие процессы ifup/ifdown
echo "Останавливаем зависшие процессы..."
pkill -f "ifup\|ifdown" 2>/dev/null || true
sleep 2

# Проверить текущий статус vmwg0
echo "Что с vmwg0:"
ip addr show vmwg0 2>/dev/null || echo "vmwg0 отсутствует"

# Принудительно удалить vmwg0 если он существует в плохом состоянии
if ip link show vmwg0 >/dev/null 2>&1; then
    echo "Пересоздаем vmwg0..."
    ip link set vmwg0 down 2>/dev/null || true
fi

# Создаем мост заново
echo "Создаем vmwg0..."
ip link add vmwg0 type bridge
ip addr add 10.10.0.1/24 dev vmwg0
ip link set vmwg0 up

# Проверяем
echo "Результат:"
ip addr show vmwg0

echo "=== Готово ==="
echo "Можно продолжать настройку"
