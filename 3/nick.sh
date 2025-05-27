#!/bin/bash

# Указываем путь к директории, которую нужно скопировать.
source_dir="/home/nick"

# Указываем путь к месту, где будет храниться резервная копия.
backup_dir="/tmp/backup"

# Имя лог-файла и его расположение.
log_file="/var/log/backup.log"

# Выполняем резервное копирование с помощью rsync.
rsync -tacv "$source_dir" "$backup_dir" &>> "$log_file"

# Проверяем код возврата rsync и записываем результат в лог-файл.
if [ $? -eq 0 ]; then
    echo "Успешное резервное копирование: $(date)" >> "$log_file"
else
    echo "Ошибка при резервном копировании: $(date)" >> "$log_file"
fi