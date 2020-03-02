# squid-proxy is transpanent proxy server

Minimal config:

    acl SSL_ports port 443
    acl Safe_ports port 80 # http
    acl Safe_ports port 21 # ftp
    acl Safe_ports port 443 # https
    acl Safe_ports port 70 # gopher
    acl Safe_ports port 210 # wais
    acl Safe_ports port 1025-65535 # unregistered ports
    acl Safe_ports port 280 # http-mgmt
    acl Safe_ports port 488 # gss-http
    acl Safe_ports port 591 # filemaker
    acl Safe_ports port 777 # multiling http
    acl CONNECT method CONNECT
    http_access allow all
    http_port 3128
    
Listening at 3128


This repo implements squid proxy

    acl localnet src 192.168.0.0/24
    acl worktime time 08:00-15:00
    acl SSL_ports port 443
    acl Safe_ports port 80          # http
    acl Safe_ports port 21          # ftp
    acl Safe_ports port 443         # https
    acl Safe_ports port 70          # gopher
    acl Safe_ports port 210         # wais
    acl Safe_ports port 1025-65535  # unregistered ports
    acl Safe_ports port 280         # http-mgmt
    acl Safe_ports port 488         # gss-http
    acl Safe_ports port 591         # filemaker
    acl Safe_ports port 777         # multiling http
    acl CONNECT method CONNECT

    acl blacklist url_regex -i "/etc/squid/blacklist"
    acl whitelist url_regex -i "/etc/squid/whitelist"

    http_access allow localhost
    http_access deny manager
    http_access deny !Safe_ports
    http_access deny CONNECT !SSL_ports
    http_access allow CONNECT
    http_access deny blacklist
    http_access allow whitelist
    http_access deny all worktime
    http_access allow all

    http_port 3128
    http_port 3129 intercept
    https_port 3130 intercept ssl-bump options=ALL:NO_SSLv3:NO_SSLv2 connection-auth=off cert=/etc/squid/squid.pem
    always_direct allow all
    sslproxy_cert_error allow all
    sslproxy_flags DONT_VERIFY_PEER

    acl blacklist_ssl ssl::server_name_regex -i "/etc/squid/blacklist_ssl"
    acl whitelist_ssl ssl::server_name_regex -i "/etc/squid/whitelist_ssl"
    acl step1 at_step SslBump1

    ssl_bump peek step1
    ssl_bump terminate blacklist_ssl
    ssl_bump splice whitelist_ssl
    ssl_bump terminate all worktime
    ssl_bump splice all

    sslcrtd_program /usr/lib/squid/ssl_crtd -s /var/lib/ssl_db -M 4MB

    #Кэш
    cache_mem 512 MB
     maximum_object_size_in_memory 512 KB
     memory_replacement_policy lru
    cache_dir aufs /var/spool/squid 2048 16 256

    #Лог
    access_log daemon:/var/log/squid/access.log squid
    logfile_rotate 1

    coredump_dir /var/spool/squid
    refresh_pattern ^ftp:           1440    20%     10080
    refresh_pattern ^gopher:        1440    0%      1440
    refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
    refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
    refresh_pattern .               0       20%     4320
    
    
Comments

Первый блок выглядит следующим образом.

    acl localnet src 192.168.0.0/24
    acl worktime time 08:00-15:00
    acl SSL_ports port 443
    acl Safe_ports port 80          # http
    acl Safe_ports port 21          # ftp
    acl Safe_ports port 443         # https
    acl Safe_ports port 70          # gopher
    acl Safe_ports port 210         # wais
    acl Safe_ports port 1025-65535  # unregistered ports
    acl Safe_ports port 280         # http-mgmt
    acl Safe_ports port 488         # gss-http
    acl Safe_ports port 591         # filemaker
    acl Safe_ports port 777         # multiling http
    acl CONNECT method CONNECT

Он отвечает за стандартные acl параметры. В нем в localnet изменяем локальную сеть на свою, а также добавляем acl рабочего времени (по желанию). Рабочее время я добавил ввиду того, что ко мне часто приходят учителя с жалобой, что не могут ничего найти, все недоступно. Я, конечно, рад, что все работает, как надо, но, честно говоря, надоело это выслушивать. Теперь на их претензию я сообщаю, что после 15.00 фильтрация отключается, и они могут свободно (почти) найти информацию, которая им нужна. Вы можете добавить свое время, или оставить фильтрацию круглосуточной, не добавляя этот acl.

Второй блок определяет списки разрешенных и запрещенных сайтов для HTTP и выглядит следующим образом.

    acl blacklist url_regex -i "/etc/squid/blacklist"
    acl whitelist url_regex -i "/etc/squid/whitelist"

Списки разрешенных и запрещенных сайтов мы добавим позже, и они будут размещаться в файлах, указанных в acl.

Третий блок определяет параметры доступа по протоколу HTTP и выглядит вот так

    http_access allow localhost
    http_access deny manager
    http_access deny !Safe_ports
    http_access deny CONNECT !SSL_ports
    http_access allow CONNECT
    http_access deny blacklist
    http_access allow whitelist
    http_access deny all worktime
    http_access allow all

Здесь пункт http_access allow CONNECT обязателен, так как без него у меня Squid не пускал в интернет никого. Далее идут правила на «черный» и «белый» списки. Параметры deny и allow запрещают и разрешают доступ соответственно. После них идет правило на полный запрет всего HTTP-трафика в рабочее время. Если вы не устанавливали рабочее время, то удалите worktime, и запрет будет постоянным. Важным моментом является порядок правил, так как Squid считывает их сверху вниз
Четвертый блок определяет параметры портов для Squid.


    http_port 3128
    http_port 3129 intercept
    https_port 3130 intercept ssl-bump options=ALL:NO_SSLv3:NO_SSLv2 connection-auth=off cert=/etc/squid/squid.pem

Первый параметр необходим, чтобы в логах бесконечно не появлялась ошибка «ERROR: No forward-proxy ports configured». Она заполняет лог и, следовательно, память. Распространенная ошибка, но, почему-то, в нашем ru-сегменте я не нашел, как ее исправить, помогли забугорские форумы. Второй параметр определяет порт HTTP протокола. Intercept означает прозрачность Proxy, то есть не будет необходимости прописывать настройки на каждом компьютере.
Третий параметр определяет порт HTTPS и его опции. Это одна длинная строка. Файл squid.pem — это наш сертификат, который мы создадим позднее.

Пятый блок определяет параметры работы SSL соединения со Squid-ом. В частности, он указывает направлять весь трафик сразу в интернет, без использования вышестоящих кешей, а последние две разрешают соединение даже с ошибками проверки сертификата, так как окончательно решение о посещении такого ресурса должен осуществлять пользователь, а не сервер. Выглядит так.

    always_direct allow all
    sslproxy_cert_error allow all
    sslproxy_flags DONT_VERIFY_PEER

Шестой блок задает параметры acl «черного» и «белого» списков, которые будут созданы позднее, а также глубину перехвата HTTPS-трафика.

    acl blacklist_ssl ssl::server_name_regex -i "/etc/squid/blacklist_ssl"
    acl whitelist_ssl ssl::server_name_regex -i "/etc/squid/whitelist_ssl"
    acl step1 at_step SslBump1

Седьмой блок определяет параметры доступа по протоколу HTTPS. Здесь за запрет и разрешение отвечают уже terminate и splice соответственно. Опять же, не забывайте убрать worktime, если у вас не указано рабочее время.

    ssl_bump peek step1
    ssl_bump terminate blacklist_ssl
    ssl_bump splice whitelist_ssl
    ssl_bump terminate all worktime
    ssl_bump splice all

    sslcrtd_program /usr/lib/squid/ssl_crtd -s /var/lib/ssl_db -M 4MB

Восьмой блок задает кеш и лог нашего Squid. Здесь стоит отметить только параметр logfile_rotate, обозначающий количество дней, в течении которых хранится лог.

    #Кеш
    cache_mem 512 MB
     maximum_object_size_in_memory 512 KB
     memory_replacement_policy lru
    cache_dir aufs /var/spool/squid 2048 16 256

    #Лог
    access_log daemon:/var/log/squid/access.log squid
    logfile_rotate 1

    coredump_dir /var/spool/squid
    refresh_pattern ^ftp:           1440    20%     10080
    refresh_pattern ^gopher:        1440    0%      1440
    refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
    refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
    refresh_pattern .               0       20%     4320

На этом настройка squid.conf закончена. Сохраняем файл и переходим к созданию сертификата и списков.

Перейдем в папку со Squid

    cd /etc/squid/

И введем следующую команду для создания сертификата

    openssl req -new -newkey rsa:1024 -days 36500 -nodes -x509 -keyout squid.pem -out squid.pem

Далее необходимо будет ввести данные сертификата. Срок действия сертификата указан 100 лет, чтобы забыть о нем надолго. Нужен он только для Proxy.

Теперь создадим наши файлы списков.

    touch blacklist
    touch whitelist
    cp whitelist whitelist_ssl
    cp blacklist blacklist_ssl

Сайты в списки заносим в виде регулярных выражений. Например, чтобы разблокировать mail.ru, откроем whitelist

    nano whitelist

и добавим в него следующее выражение.

    mail\.ru 

Теперь заблокируем Игры.Mail.ru. Откроем наш blacklist

    nano blacklist

и запишем в него следующее выражение

    games\.mail\.ru

Так как правило, блокирующее по черному списку, стоит у нас выше белого списка, то, при переходе на mail.ru, сайт будет открываться как положено (за исключением картинок, но об этом позже), а если попытаться перейти на Игры, Squid нас не пустит.

У некоторых сайтов множество поддоменов, субдоменов и т.д. Как, например, mail.ru хранит свои картинки на imgsmail.ru. Касаемо других подобных сайтов, вам необходимо в любом браузере (я использую Chrome) открыть нужный сайт и, следом, инструменты разработчика (в Chrome вызываются по клавише F12).



Перейти на вкладку Sources и посмотреть, с каких еще ресурсов сайт подгружает информацию.

Добавив сайты, скопируем их в списки для HTTPS.

    cp whitelist whitelist_ssl
    cp blacklist blacklist_ssl

Совет по заполнению списков
Теперь проверим конфигурацию.

    squid -k check

Если все хорошо, остановим Squid.

    /etc/init.d/squid stop

Перестроим кеш

    squid -z

И снова запустим Squid

    /etc/init.d/squid start

После любого изменения списков или конфигурации Squid, его необходимо перезагружать командой

    /etc/init.d/squid restart

Также можете изменить страницу запрета доступа (работает только на HTTP) по пути /usr/share/squid/errors/~Russian-1251. Ищите в папке файл ERR_ACCESS_DENIED и редактируете его. Синтаксис файла — HTML.
    
# Links

* https://habr.com/ru/post/267851/
* https://habr.com/ru/post/473584/
* https://habr.com/ru/post/314718/
* https://habr.com/ru/post/53542/
* https://habr.com/ru/post/136205/
* https://habr.com/ru/post/272733/
