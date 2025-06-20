#!/bin/bash
# Скрипт быстрого восстановления сетевого интерфейса
# Запустите это, если playbook зависает на сетевых операциях

echo "=== Восстановление сетевого интерфейса ==="

# Завершить любые зависшие процессы ifup/ifdown
echo "Завершение зависших сетевых процессов..."
pkill -f "ifup\|ifdown" 2>/dev/null || true
sleep 2

# Проверить текущий статус vmwg0
echo "Текущий статус vmwg0:"
ip addr show vmwg0 2>/dev/null || echo "vmwg0 не существует"

# Принудительно удалить vmwg0 если он существует в плохом состоянии
if ip link show vmwg0 >/dev/null 2>&1; then
    echo "Удаление существующего vmwg0..."
    ip link set vmwg0 down 2>/dev/null || true
    ip link delete vmwg0 2>/dev/null || true
fi

# Пересоздать мост vmwg0
echo "Создание моста vmwg0..."
ip link add vmwg0 type bridge
ip addr add 10.10.0.1/24 dev vmwg0
ip link set vmwg0 up

# Проверить
echo "Новый статус vmwg0:"
ip addr show vmwg0

echo "=== Восстановление завершено ==="
echo "Теперь вы можете продолжить развертывание"
