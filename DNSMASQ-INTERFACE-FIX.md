# Исправление ошибки "unknown interface vmwg0" в dnsmasq

## Проблема

Сервис `dnsmasq@vmwgnat` не может запуститься с ошибкой:
```
dnsmasq: unknown interface vmwg0
FAILED to start up
```

## Причина

1. **Порядок запуска**: dnsmasq пытается запуститься до того, как интерфейс `vmwg0` создан и поднят
2. **Строгая привязка**: `bind-interfaces` требует наличия интерфейса при запуске
3. **Отсутствие зависимостей**: systemd не знает о зависимости от сетевого интерфейса

## ✅ Решение

### 1. Изменена конфигурация dnsmasq
**Было:** `bind-interfaces` (требует интерфейс при запуске)  
**Стало:** `bind-dynamic` (ждет появления интерфейса)

### 2. Добавлены systemd зависимости
```ini
# /etc/systemd/system/dnsmasq@vmwgnat.service.d/override.conf
[Unit]
After=network-online.target
Wants=network-online.target
# Start after vmwg0 interface is configured
After=sys-subsystem-net-devices-vmwg0.device
Wants=sys-subsystem-net-devices-vmwg0.device
```

### 3. Улучшен порядок запуска в плейбуке
1. Поднимается интерфейс `vmwg0`
2. Проверяется готовность интерфейса  
3. Пауза 2 секунды для стабилизации
4. Финальная проверка состояния `UP`
5. Запуск `dnsmasq@vmwgnat`

### 4. Добавлен диагностический скрипт
```bash
/root/debug-dnsmasq.sh
```

## 🔧 Файлы изменены

- `templates/dnsmasq-default.conf.j2` - изменено на `bind-dynamic`
- `deploy-vmwg-subnet.yml` - добавлены проверки и зависимости
- `cleanup-vmwg-subnet.yml` - обновлен для новых файлов
- `templates/debug-dnsmasq.sh.j2` - новый диагностический скрипт

## 📋 Для применения

```bash
# Развернуть исправленную версию
ansible-playbook deploy-vmwg-subnet.yml

# Если проблемы остались - диагностика
ssh root@pve-host
/root/debug-dnsmasq.sh
```

## 🚀 Проверка результата

```bash
# Проверить статус
systemctl status dnsmasq@vmwgnat

# Проверить интерфейс
ip addr show vmwg0

# Проверить DHCP
cat /var/lib/misc/dnsmasq.vmwgnat.leases
```

## 💡 Дополнительная диагностика

Если проблемы остались:

```bash
# Ручной тест конфигурации
dnsmasq --test --conf-dir=/etc/dnsmasq.d/vmwgnat,*.conf

# Запуск в debug режиме
dnsmasq --no-daemon --log-queries --conf-dir=/etc/dnsmasq.d/vmwgnat,*.conf

# Проверка зависимостей systemd
systemctl list-dependencies dnsmasq@vmwgnat
```
