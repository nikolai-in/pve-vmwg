#!/bin/bash
# Проверка настройки репозитория и предварительных требований

set -e

echo "🔍 Проверка настройки сети ВМ Proxmox"
echo "===================================="
echo

# Проверяем, что мы в правильной директории
if [[ ! -f "deploy-vmwg-subnet.yml" ]]; then
    echo "❌ Ошибка: Не в правильной директории"
    echo "Пожалуйста, запустите этот скрипт из корня репозитория vmwg0"
    exit 1
fi

echo "✅ Структура репозитория выглядит правильно"

# Проверяем установку Ansible
if ! command -v ansible >/dev/null 2>&1; then
    echo "❌ Ansible не установлен"
    echo "Установите с помощью: pip install ansible"
    exit 1
fi

echo "✅ Ansible установлен: $(ansible --version | head -1)"

# Проверяем файл инвентаря
if [[ ! -f "inventory.yml" ]]; then
    echo "❌ inventory.yml не найден"
    echo "Пожалуйста, создайте inventory.yml с конфигурацией вашего хоста Proxmox"
    exit 1
fi

echo "✅ inventory.yml найден"

# Тестируем подключение
echo
echo "🔗 Тестирование подключения к хосту Proxmox..."
if ansible proxmox_hosts -m ping -o; then
    echo "✅ Хост Proxmox доступен"
else
    echo "❌ Не удается достичь хост Proxmox"
    echo "Проверьте ваш inventory.yml и SSH подключение"
    exit 1
fi

echo
echo "📋 Сводка инвентаря:"
ansible-inventory --list --yaml | head -20

echo
echo "🔧 Статус системы резервирования:"
echo "- Унифицированный скрипт: src/network-failsafe"
echo "- Экстренное восстановление: src/recover-network.sh"
echo "- Шаблоны: $(find templates/ -name '*.j2' | wc -l) шаблонов Jinja2"

echo
echo "✅ Проверка настройки завершена!"
echo
echo "🚀 Готов к развертыванию!"
echo "Запустите: ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml"
