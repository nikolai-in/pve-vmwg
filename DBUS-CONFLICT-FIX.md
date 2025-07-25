# Исправление конфликта D-Bus с стандартным Proxmox SDN

## Проблема

После предыдущего фикса D-Bus, стандартные SDN сети Proxmox перестали работать из-за конфликта имен сервисов D-Bus.

### Симптомы

```bash
root@host:~# systemctl status dnsmasq@dhcpsnat.service
dnsmasq-dhcp[37304]: DHCPDISCOVER(vnet0) bc:24:11:1a:96:c5 no address available
```

## Причина

Оба сервиса пытались использовать одно и то же имя D-Bus: `uk.org.thekelleys.dnsmasq.dhcpsnat`

## Решение

### 1. Изменено имя D-Bus сервиса

**Было:** `uk.org.thekelleys.dnsmasq.dhcpsnat`  
**Стало:** `uk.org.thekelleys.dnsmasq.vmwgnat`

### 2. Добавлены ограничения по интерфейсу

- `interface=vmwg0` - работаем только с нашим интерфейсом
- `bind-interfaces` - привязываемся строго к указанным интерфейсам
- Удалена директива `bind-dynamic`

### 3. Автоматическая очистка

Плейбук теперь автоматически удаляет старый D-Bus файл при развертывании.

### 4. Файлы изменены

- `templates/dnsmasq-dhcpsnat.conf.j2` → `templates/dnsmasq-vmwgnat.conf.j2`
- `templates/dnsmasq-default.conf.j2` - добавлены ограничения интерфейса
- `templates/dnsmasq-vmwg0.conf.j2` - убрано дублирование interface
- `deploy-vmwg-subnet.yml` - обновлены пути и добавлена очистка

## Проверка исправления

### 1. Перезапустить плейбук

```bash
ansible-playbook deploy-vmwg-subnet.yml
```

### 2. Проверить статус сервисов

```bash
# Наш сервис
systemctl status dnsmasq@vmwgnat.service

# Стандартный Proxmox SDN
systemctl status dnsmasq@dhcpsnat.service
```

### 3. Проверить D-Bus сервисы

```bash
# Наш D-Bus сервис
dbus-send --system --dest=uk.org.thekelleys.dnsmasq.vmwgnat --print-reply / org.freedesktop.DBus.Introspectable.Introspect

# Стандартный D-Bus сервис (должен быть доступен)
dbus-send --system --dest=uk.org.thekelleys.dnsmasq.dhcpsnat --print-reply / org.freedesktop.DBus.Introspectable.Introspect
```

### 4. Проверить работу контейнеров

```bash
pct start <container_id>
```

## Совместимость

Теперь наша система работает параллельно со стандартным Proxmox SDN без конфликтов:

- **vmwgnat** (наш) - обслуживает `vmwg0` интерфейс, VPN подсеть 10.10.0.0/24
- **dhcpsnat** (Proxmox) - обслуживает стандартные SDN сети (vnet0, vnet1, etc.)

Каждый сервис имеет свой D-Bus endpoint и работает со своими интерфейсами.
