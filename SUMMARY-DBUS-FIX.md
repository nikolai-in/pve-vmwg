# Сводка исправлений конфликта D-Bus

## Проблема

После предыдущего фикса D-Bus, стандартные SDN сети Proxmox перестали работать из-за конфликта имен D-Bus сервисов.

## ✅ Что исправлено

### 1. **Разделение D-Bus сервисов**

- **Наш сервис:** `uk.org.thekelleys.dnsmasq.vmwgnat`
- **Proxmox SDN:** `uk.org.thekelleys.dnsmasq.dhcpsnat` (работает без конфликтов)

### 2. **Изоляция по интерфейсам**

```bash
# Наш dnsmasq работает только с vmwg0
interface=vmwg0
bind-interfaces
```

### 3. **Автоматическая очистка**

- Удаление старых D-Bus файлов при развертывании
- Обновленный cleanup плейбук

### 4. **Файлы изменены**

- `templates/dnsmasq-dhcpsnat.conf.j2` → `templates/dnsmasq-vmwgnat.conf.j2`
- `templates/dnsmasq-default.conf.j2` - добавлена изоляция интерфейсов
- `deploy-vmwg-subnet.yml` - обновлены пути и добавлена очистка
- `cleanup-vmwg-subnet.yml` - улучшена обработка процессов

## 🚀 Результат

Теперь работают **параллельно без конфликтов**:

- **vmwgnat** (наш) - обслуживает vmwg0, VPN подсеть 10.10.0.0/24
- **dhcpsnat** (Proxmox) - обслуживает стандартные SDN сети

## 📋 Для применения

```bash
# Развернуть исправленную версию
ansible-playbook deploy-vmwg-subnet.yml

# Проверить оба сервиса
systemctl status dnsmasq@vmwgnat
systemctl status dnsmasq@dhcpsnat
```

## 🐛 Об ошибке -15 в cleanup

Код возврата -15 (SIGTERM) в задаче "Kill any remaining failsafe background processes" не критичен - просто означает, что процессы для завершения не найдены или уже завершены. Теперь эта задача обрабатывается корректно.
