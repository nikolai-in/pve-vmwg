# Proxmox: подсеть ВМ через WireGuard

Ansible-скрипты для настройки изолированной подсети ВМ на Proxmox. Весь трафик ВМ идет через WireGuard VPN. С защитой от потери доступа к серверу.

## Содержание

- [Быстрый старт](#быстрый-старт)
- [Что получится](#что-получится)
- [Настройка](#настройка)
- [Защита от блокировки](#защита-от-блокировки)
- [Тестирование системы](#тестирование-системы)
- [Создание ВМ](#создание-вм)
- [Экстренное восстановление](#экстренное-восстановление)
- [Структура проекта](#структура-проекта)

## Быстрый старт

```bash
# Настроить инвентарь
cp inventory.example.yml inventory.yml
# отредактировать inventory.yml с вашими данными

# Проверить что все готово
./verify-setup.sh

# Настроить сеть (с защитой от блокировки)
ansible-playbook deploy-vmwg-subnet.yml

# Убрать все настройки
ansible-playbook cleanup-vmwg-subnet.yml
```

## Что получится

- **Мост vmwg0** (10.10.0.1/24) — к нему подключаются ВМ
- **DHCP** через dnsmasq раздает IP 10.10.0.2-254  
- **VPN**: весь трафик ВМ через WireGuard
- **Защита**: откатывается автоматически, если что-то сломается

## Настройка

### Скопировать пример конфига

```bash
cp inventory.example.yml inventory.yml
```

### Заполнить свои данные в inventory.yml

```yaml
proxmox_hosts:
  hosts:
    pve:
      ansible_host: 10.1.10.1
      wireguard_private_key: "ваш_приватный_ключ"
      wireguard_address: "10.8.0.10/24, fdcc:ad94:bacf:61a4::cafe:a/112"
      wireguard_peer_public_key: "публичный_ключ_сервера"
      wireguard_preshared_key: "pre_shared_ключ"
      wireguard_endpoint: "ваш.сервер.com:51820"
```

### Развернуть

```bash
ansible-playbook deploy-vmwg-subnet.yml
```

## Защита от блокировки

Чтобы не потерять доступ к серверу при настройке сети:

### Как работает

1. Сохраняет текущие настройки
2. Ставит таймер на 5 минут  
3. Если все ОК — отключается сама
4. Если сломалось — откатывает обратно

### Команды

```bash
network-failsafe status          # статус
network-failsafe test            # тест на 15 секунд
network-failsafe arm 300         # включить на 5 минут
network-failsafe disarm          # выключить
```

## Тестирование системы

### Быстрая проверка

SSH на Proxmox и запустить:

```bash
# Статус защиты
network-failsafe status

# Автотест (15 сек, безопасно)
network-failsafe test

# Диагностика сети
/root/debug-vmwg0.sh
```

### Ручное тестирование

```bash
# Включить защиту на 1 минуту
network-failsafe arm 60

# Посмотреть что происходит
tail -f /var/log/network-failsafe.log

# Досрочно выключить (опционально)
network-failsafe disarm
```

### Проверка сети

```bash
# Интерфейсы
ip addr show vmwg0

# Сервисы  
systemctl status wg-quick@wg0
systemctl status dnsmasq@vmwgnat

# NAT правила
iptables -t nat -L POSTROUTING | grep 10.10.0

# Таблица маршрутизации
ip rule show | grep 200
```

### Если что-то сломалось

```bash
# Проверить процессы защиты
ps aux | grep network-failsafe

# Почистить зависшие процессы
pkill -f network-failsafe
rm -f /tmp/network-failsafe.lock

# Логи
tail -20 /var/log/network-failsafe.log
```

## Создание ВМ

В веб-интерфейсе Proxmox:

1. Создать ВМ
2. В сетевых настройках выбрать мост `vmwg0`
3. ВМ получат IP из 10.10.0.2-254
4. Весь трафик пойдет через WireGuard

## Экстренное восстановление  

### Из консоли/IPMI

```bash
# Быстрое восстановление сети
/usr/local/bin/recover-network.sh

# Через систему защиты
network-failsafe restore
```

### Полное восстановление

```bash
# Если совсем всё плохо
ansible-playbook cleanup-vmwg-subnet.yml
```

### Настройка переменных

В `deploy-vmwg-subnet.yml` можно изменить:

```yaml
vars:
  vm_subnet: "10.10.0.0/24"           # подсеть ВМ
  vm_gateway: "10.10.0.1"             # шлюз  
  vm_dhcp_range_start: "10.10.0.2"    # начало DHCP
  vm_dhcp_range_end: "10.10.0.254"    # конец DHCP
  routing_table_id: 200               # ID таблицы маршрутизации
```

## Структура проекта

```text
├── deploy-vmwg-subnet.yml      # основной плейбук
├── cleanup-vmwg-subnet.yml     # удаление всего
├── inventory.yml               # ваш конфиг (создать из .example)
├── inventory.example.yml       # пример конфига
├── ansible.cfg                 # настройки Ansible
├── verify-setup.sh             # проверка готовности
├── src/
│   ├── network-failsafe        # скрипт защиты сети
│   └── recover-network.sh      # аварийное восстановление
└── templates/                  # шаблоны конфигов
    ├── debug-vmwg0.sh.j2       # диагностика
    ├── dnsmasq-default.conf.j2 # базовая настройка dnsmasq
    ├── dnsmasq-vmwg0.conf.j2   # DHCP для vmwg0
    ├── dnsmasq@.service.j2     # systemd сервис
    ├── vmwgnat.j2              # сетевой интерфейс
    └── wg0.conf.j2             # конфиг WireGuard
```

## Требования

- Proxmox VE
- Ansible
- SSH доступ к Proxmox хосту
- Данные WireGuard сервера
