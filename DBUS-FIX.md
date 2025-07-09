# Исправление проблемы D-Bus с dnsmasq

## Проблема
Контейнер LXC не запускается с ошибкой:
```
The name uk.org.thekelleys.dnsmasq.dhcpsnat was not provided by any .service files
```

## Причина
Proxmox ожидает D-Bus интеграцию с dnsmasq для управления DHCP, но наш dnsmasq запущен без D-Bus поддержки.

## Решение

### Автоматическое исправление (рекомендуемый)
Запустите обновленный плейбук:
```bash
ansible-playbook deploy-vmwg-subnet.yml
```

Это добавит:
1. D-Bus поддержку в dnsmasq конфигурацию
2. D-Bus политику для сервиса dhcpsnat
3. Перезагрузит dnsmasq и D-Bus

### Ручное исправление

1. **Добавить D-Bus поддержку в dnsmasq:**
```bash
echo "enable-dbus=uk.org.thekelleys.dnsmasq.dhcpsnat" >> /etc/dnsmasq.d/vmwgnat/00-default.conf
```

2. **Создать D-Bus политику:**
```bash
cat > /etc/dbus-1/system.d/dnsmasq-dhcpsnat.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy user="root">
    <allow own="uk.org.thekelleys.dnsmasq.dhcpsnat"/>
    <allow send_destination="uk.org.thekelleys.dnsmasq.dhcpsnat"/>
    <allow receive_sender="uk.org.thekelleys.dnsmasq.dhcpsnat"/>
  </policy>
  <policy user="www-data">
    <allow send_destination="uk.org.thekelleys.dnsmasq.dhcpsnat"/>
    <allow receive_sender="uk.org.thekelleys.dnsmasq.dhcpsnat"/>
  </policy>
  <policy context="default">
    <allow send_destination="uk.org.thekelleys.dnsmasq.dhcpsnat"/>
    <allow receive_sender="uk.org.thekelleys.dnsmasq.dhcpsnat"/>
  </policy>
</busconfig>
EOF
```

3. **Перезагрузить сервисы:**
```bash
systemctl reload dbus
systemctl restart dnsmasq@vmwgnat
```

### Проверка исправления

1. **Проверить D-Bus сервис:**
```bash
dbus-send --system --dest=uk.org.thekelleys.dnsmasq.dhcpsnat --print-reply / org.freedesktop.DBus.Introspectable.Introspect
```

2. **Попробовать запустить контейнер:**
```bash
pct start 222
```

### Альтернативное решение
Если D-Bus интеграция не нужна, можно отключить её в настройках контейнера:
```bash
# В файле /etc/pve/lxc/222.conf добавить:
# features: fuse=1,nesting=1,keyctl=1,mknod=1
```

## Объяснение
Proxmox использует D-Bus для динамического управления DHCP арендами через dnsmasq. Когда контейнер запускается, Proxmox пытается зарегистрировать его MAC адрес в DHCP через D-Bus интерфейс dnsmasq. Без этой интеграции hook скрипт завершается с ошибкой.
