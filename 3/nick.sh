#!/bin/bash

# ��������� ���� � ����������, ������� ����� �����������.
source_dir="/home/nick"

# ��������� ���� � �����, ��� ����� ��������� ��������� �����.
backup_dir="/tmp/backup"

# ��� ���-����� � ��� ������������.
log_file="/var/log/backup.log"

# ��������� ��������� ����������� � ������� rsync.
rsync -tacv "$source_dir" "$backup_dir" &>> "$log_file"

# ��������� ��� �������� rsync � ���������� ��������� � ���-����.
if [ $? -eq 0 ]; then
    echo "�������� ��������� �����������: $(date)" >> "$log_file"
else
    echo "������ ��� ��������� �����������: $(date)" >> "$log_file"
fi