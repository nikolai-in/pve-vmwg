# Переводы на русский язык

Этот проект включает переводы документации и инструментов на русский язык.

## Русские файлы

### Документация

- `README.ru.md` - Основная документация на русском языке
- `MANUAL-FAILSAFE-TESTING.ru.md` - Руководство по тестированию резервирования

### Инструменты

- `verify-setup.ru.sh` - Скрипт проверки настройки
- `src/network-failsafe.ru` - Основной скрипт управления резервированием
- `src/recover-network.ru.sh` - Скрипт экстренного восстановления сети

## Быстрый старт на русском

```bash
# Проверить настройку
./verify-setup.ru.sh

# Развернуть систему
ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml

# Проверить статус резервирования (на хосте Proxmox)
src/network-failsafe.ru status

# Протестировать резервирование
src/network-failsafe.ru test

# Очистка
ansible-playbook -i inventory.yml cleanup-vmwg-subnet.yml
```

## Основные команды резервирования

```bash
# Статус
network-failsafe.ru status

# Активировать на 5 минут
network-failsafe.ru arm

# Быстрый тест (15 секунд)
network-failsafe.ru test

# Отключить
network-failsafe.ru disarm

# Восстановить из снимка
network-failsafe.ru restore
```

## Экстренное восстановление

Если потеряли доступ к сети:

```bash
# Из консоли/IPMI на хосте Proxmox
/usr/local/bin/recover-network.ru.sh

# Или используйте Ansible для полной очистки
ansible-playbook -i inventory.yml cleanup-vmwg-subnet.yml
```

Все оригинальные английские файлы остаются без изменений.
