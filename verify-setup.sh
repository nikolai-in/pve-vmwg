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
echo "🔗 Пингуем Proxmox..."
if ansible proxmox_hosts -m ping -o; then
    echo "✅ Сервер доступен"
else
    echo "❌ Сервер недоступен"
    echo "Проверьте inventory.yml и SSH"
    exit 1
fi

echo
echo "📋 Что настроено:"
ansible-inventory --list --yaml | head -20

echo
echo "🔧 Скрипты защиты:"
echo "- Основной: src/network-failsafe"
echo "- Аварийный: src/recover-network.sh"
echo "- Шаблонов: $(find templates/ -name '*.j2' | wc -l)"

echo
echo "✅ Все готово!"
echo
echo "🚀 Запускаем:"
echo "ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml"
