#!/bin/bash
# Проверяем готовность системы к развертыванию

set -e

echo "🔍 Проверка готовности к настройке Proxmox"
echo "========================================="
echo

# Проверяем, что мы в правильной директории
if [[ ! -f "deploy-vmwg-subnet.yml" ]]; then
    echo "❌ Запускайте скрипт из папки проекта"
    echo "Нужен файл deploy-vmwg-subnet.yml в текущей директории"
    exit 1
fi

echo "✅ Файлы проекта найдены"

# Проверяем установку Ansible
if ! command -v ansible >/dev/null 2>&1; then
    echo "❌ Нужно установить Ansible"
    echo "Команда: pip install ansible"
    exit 1
fi

echo "✅ Ansible работает: $(ansible --version | head -1)"

# Проверяем файл инвентаря
if [[ ! -f "inventory.yml" ]]; then
    echo "❌ Отсутствует inventory.yml"
    echo "Создайте файл с настройками вашего Proxmox-сервера"
    exit 1
fi

echo "✅ Конфиг сервера найден"

# Тестируем подключение
echo
echo "🔗 Проверяем связь с Proxmox..."
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
