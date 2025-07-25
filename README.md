# Proxmox: подсеть ВМ через WireGuard

Ansible-скрипты для создания подсети ВМ на Proxmox. Весь трафик ВМ идет через WireGuard VPN.

**✅ Совместимо с Proxmox SDN** - использует стандартные механизмы Proxmox.

## Что получится

- **Мост vmwg0** (10.10.0.1/24) — к нему подключаются ВМ
- **DHCP** через dnsmasq раздает IP 10.10.0.2-254
- **VPN**: весь трафик ВМ через WireGuard
- **Защита**: откатывается автоматически при потере SSH

## Быстрый старт

1. Скопировать `inventory.example.yml` в `inventory.yml`
2. Заполнить свои данные в `inventory.yml`
3. Развернуть: `ansible-playbook deploy-vmwg-subnet.yml`
4. Откатить при необходимости: `ansible-playbook cleanup-vmwg-subnet.yml`

## Конфигурация

В `deploy-vmwg-subnet.yml` можно изменить:

```yaml
vars:
  vm_subnet: "10.10.0.0/24"        # подсеть ВМ
  vm_gateway: "10.10.0.1"          # шлюз
  vm_dhcp_range_start: "10.10.0.2" # начало DHCP
  vm_dhcp_range_end: "10.10.0.254" # конец DHCP
  routing_table_id: 200            # ID таблицы маршрутизации
```

## Безопасность

Система автоматически создает резервную копию сетевой конфигурации и восстанавливает её через 5 минут если SSH недоступен:

```bash
# Статус защиты
network-failsafe status

# Тест системы (15 сек)
network-failsafe test

# Диагностика
/root/debug-vmwg0.sh
```

## Совместимость с Proxmox SDN

- ✅ Использует стандартный `/lib/systemd/system/dnsmasq@.service`
- ✅ Создает `/etc/default/dnsmasq.vmwgnat` для конфигурации
- ✅ Не конфликтует с D-Bus интеграцией SDN зон
- ✅ Безопасен при обновлениях Proxmox

## Архитектура

```text
ВМ (10.10.0.x) → Мост vmwg0 → NAT → WireGuard wg0 → Интернет
                     ↓
                  DHCP (dnsmasq@vmwgnat)
```

**Policy-based routing**: трафик ВМ идет через отдельную таблицу маршрутизации (200) и WireGuard, трафик хоста — напрямую.

## Требования

- Proxmox VE
- Ansible
- SSH доступ к Proxmox хосту
- Данные WireGuard сервера (ключи, endpoint)

## Создаваемые файлы

- `/etc/wireguard/wg0.conf` - конфигурация VPN
- `/etc/network/interfaces.d/vmwgnat` - сетевой интерфейс vmwg0
- `/etc/dnsmasq.d/vmwgnat/` - конфигурация DHCP
- `/etc/default/dnsmasq.vmwgnat` - настройки systemd сервиса
- `/usr/local/bin/network-failsafe` - система защиты
- `/root/debug-vmwg0.sh` - диагностический скрипт
