# Домашнее задание к занятию 1 «Disaster recovery и Keepalived»


### Задание 1
- Дана [схема](1/hsrp_advanced.pkt) для Cisco Packet Tracer, рассматриваемая в лекции.
- На данной схеме уже настроено отслеживание интерфейсов маршрутизаторов Gi0/1 (для нулевой группы)
- Необходимо аналогично настроить отслеживание состояния интерфейсов Gi0/0 (для первой группы).
- Для проверки корректности настройки, разорвите один из кабелей между одним из маршрутизаторов и Switch0 и запустите ping между PC0 и Server0.
- На проверку отправьте получившуюся схему в формате pkt и скриншот, где виден процесс настройки маршрутизатора.


### *Ответ*

Настроил track на int gig0/1 для отслеживания состояния gig0/0

Указал приоритет 45 на Router2, чтобы было переключение. [pkt файл](./hsrp_advanced(edited).pkt)

![](./homework-1/image-01.jpg)


### Задание 2
- Запустите две виртуальные машины Linux, установите и настройте сервис Keepalived как в лекции, используя пример конфигурационного [файла](1/keepalived-simple.conf).
- Настройте любой веб-сервер (например, nginx или simple python server) на двух виртуальных машинах
- Напишите Bash-скрипт, который будет проверять доступность порта данного веб-сервера и существование файла index.html в root-директории данного веб-сервера.
- Настройте Keepalived так, чтобы он запускал данный скрипт каждые 3 секунды и переносил виртуальный IP на другой сервер, если bash-скрипт завершался с кодом, отличным от нуля (то есть порт веб-сервера был недоступен или отсутствовал index.html). Используйте для этого секцию vrrp_script
- На проверку отправьте получившейся bash-скрипт и конфигурационный файл keepalived, а также скриншот с демонстрацией переезда плавающего ip на другой сервер в случае недоступности порта или файла index.html

### *Ответ*

*Скрипт*

```sh
#!/bin/bash

# IP-адрес и порт веб-сервера, который нужно проверить
web_server_ip="192.168.0.136"    # Принимает ip первой переменной
web_server_port="80"  # Принимает порт второй переменной

# Функция для проверки доступности порта
check_port() {
    nc -z -w1 "$web_server_ip" "$web_server_port"
    return $?
}

# Функция для проверки существования файла index.html
check_index_html() {
    curl --head --silent --fail "http://$web_server_ip/index.html" > /dev/null
    return $?
}

# Проверяем доступность порта
if check_port; then
     echo "PORT AVAILABLE"
    # Проверяем существование файла index.html
    if check_index_html; then
         echo "index available"
        # Если порт и файл index.html доступны, возвращаем код 1
        exit 1
    else
         echo "index unavailable"
        # Если порт доступен, но файл index.html не найден, возвращаем код 0
        exit 0
    fi
else
    # Если порт недоступен, возвращаем код 0
     echo "PORT UNAVAILABLE"
    exit 0
fi
```

keepalived.conf
```yml
global_defs {
  enable_script_security
  script_user root
}

vrrp_script check_web {

        script "/etc/keepalived/testweb.sh"
        interval 2
        weight 10
}



vrrp_instance web {
    state BACKUP
    interface enp0s3
    virtual_router_id 254
    priority 95
    advert_int 1

    virtual_ipaddress {
        192.168.0.220
    }

    track_script {
        check_web #скрипт отслеживания
    }
}
```


### Задание 3*
- Изучите дополнительно возможность Keepalived, которая называется vrrp_track_file
- Напишите bash-скрипт, который будет менять приоритет внутри файла в зависимости от нагрузки на виртуальную машину (можно разместить данный скрипт в cron и запускать каждую минуту). Рассчитывать приоритет можно, например, на основании Load average.
- Настройте Keepalived на отслеживание данного файла.
- Нагрузите одну из виртуальных машин, которая находится в состоянии MASTER и имеет активный виртуальный IP и проверьте, чтобы через некоторое время она перешла в состояние SLAVE из-за высокой нагрузки и виртуальный IP переехал на другой, менее нагруженный сервер.
- Попробуйте выполнить настройку keepalived на третьем сервере и скорректировать при необходимости формулу так, чтобы плавающий ip адрес всегда был прикреплен к серверу, имеющему наименьшую нагрузку.
- На проверку отправьте получившийся bash-скрипт и конфигурационный файл keepalived, а также скриншоты логов keepalived с серверов при разных нагрузках


### *Ответ*

keepalived.conf

```yml
global_defs {
  enable_script_security
  script_user root
}

vrrp_script check_web {

        script "/etc/keepalived/testweb.sh"
        interval 2
        weight 10
}

track_file loadvalue {

        file "/etc/keepalived/loadvalue"

        weight -2

}



vrrp_instance web {
    state BACKUP
    interface enp0s3
    virtual_router_id 254
    priority 95
    advert_int 1

    virtual_ipaddress {
        192.168.0.220
    }

    track_file {

        loadvalue #файл нагрузки

    }


    track_script {
        check_web #скрипт отслеживания
    }
}

```

Скрипт в cron для изменения файла путем записи в него значения loadavg умноженного на 35

```sh

#!/bin/bash

# Читаем значение loadavg
loadavg=$(cat /proc/loadavg)

# Извлекаем среднюю загрузку (1 минута) из значения loadavg
loadavg_1min=$(echo "$loadavg" | awk '{print $1}')

# Умножаем значение на 10 и округляем до целого числа
loadavg_int=$(awk -v loadvalue="$loadavg_1min" 'BEGIN{printf "%.0f", loadvalue*35}')

# Записываем полученное значение в файл
echo "$loadavg_int" > /etc/keepalived/loadvalue

```


Пара скринов что всё работает

![](./homework-1/image-02.jpg)

![](./homework-1/image-03.jpg)

![](./homework-1/alive.gif)