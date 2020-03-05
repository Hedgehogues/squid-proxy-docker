# Docker

You can 

    docker run -p 3128:3128 squid
    
Or you can use docker-compose:

    docker-compose up

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
    
    
# Comments of config

### The first block

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

He is responsible for standard acl parameters. In it, in localnet, we change the local network to our own, and also add acl of working time (optional). I added working time in view of the fact that teachers often come to me complaining that they cannot find anything, everything is inaccessible. Of course, I'm glad that everything works as it should, but, frankly, I'm tired of listening to this. Now I’m reporting their claim that after 15:00 the filtering is turned off and they can freely (almost) find the information they need. You can add your time, or leave filtering around the clock without adding this acl.

### The second block

The second block defines the lists of allowed and forbidden sites for HTTP and looks as follows.

    acl blacklist url_regex -i "/etc/squid/blacklist"
    acl whitelist url_regex -i "/etc/squid/whitelist"

We will add lists of allowed and forbidden sites later, and they will be placed in files specified in acl.

### The third block

The third block determines the access parameters via HTTP and looks like this

    http_access allow localhost
    http_access deny manager
    http_access deny !Safe_ports
    http_access deny CONNECT !SSL_ports
    http_access allow CONNECT
    http_access deny blacklist
    http_access allow whitelist
    http_access deny all worktime
    http_access allow all
    
Here the item http_access allow CONNECT is required, since without it Squid would not let anyone on the Internet. Next are the rules on the black and white lists. The deny and allow parameters deny and allow access, respectively. After them comes the rule to completely ban all HTTP traffic during business hours. If you did not set working hours, then delete worktime, and the ban will be permanent. An important point is the order of the rules, as Squid reads them from top to bottom

### The fourth block

The fourth block defines the port settings for Squid.

    http_port 3128
    http_port 3129 intercept
    https_port 3130 intercept ssl-bump options=ALL:NO_SSLv3:NO_SSLv2 connection-auth=off cert=/etc/squid/squid.pem

The first parameter is necessary so that the “ERROR: No forward-proxy ports configured” error does not appear infinitely in the logs. It fills the log and, therefore, the memory. A common mistake, but for some reason, in our ru-segment I did not find how to fix it, foreign forums helped. The second parameter defines the HTTP protocol port. Intercept means Proxy transparency, that is, there will be no need to prescribe settings on each computer.

The third parameter defines the HTTPS port and its options. This is one long line. The squid.pem file is our certificate, which we will create later.

### The fifth block

The fifth block defines the parameters of the SSL connection with Squid. In particular, he indicates that all traffic should be directed immediately to the Internet, without using higher caches, and the last two allow connections even with certificate verification errors, since the decision to visit such a resource must be made by the user, not the server. Looks like that.

    always_direct allow all
    sslproxy_cert_error allow all
    sslproxy_flags DONT_VERIFY_PEER

### The sixth block

The sixth block sets the acl parameters of the “black” and “white” lists, which will be created later, as well as the depth of interception of HTTPS traffic.

    acl blacklist_ssl ssl::server_name_regex -i "/etc/squid/blacklist_ssl"
    acl whitelist_ssl ssl::server_name_regex -i "/etc/squid/whitelist_ssl"
    acl step1 at_step SslBump1

### The seventh block

The seventh block determines the access parameters using the HTTPS protocol. Here, the ban and permission are already responsible for terminate and splice, respectively. Again, do not forget to remove worktime if you do not have a specified working time.

    ssl_bump peek step1
    ssl_bump terminate blacklist_ssl
    ssl_bump splice whitelist_ssl
    ssl_bump terminate all worktime
    ssl_bump splice all

    sslcrtd_program /usr/lib/squid/ssl_crtd -s /var/lib/ssl_db -M 4MB

### The eighth block

The eighth block sets the cache and log of our Squid. Here it is worth noting only the logfile_rotate parameter, which indicates the number of days during which the log is stored.

    # Cache
    
    cache_mem 512 MB
     maximum_object_size_in_memory 512 KB
     memory_replacement_policy lru
    cache_dir aufs /var/spool/squid 2048 16 256

    # Log
    access_log daemon:/var/log/squid/access.log squid
    logfile_rotate 1

    coredump_dir /var/spool/squid
    refresh_pattern ^ftp:           1440    20%     10080
    refresh_pattern ^gopher:        1440    0%      1440
    refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
    refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
    refresh_pattern .               0       20%     4320

This completes the setup of squid.conf. We save the file and proceed to the creation of the certificate and lists.

# Starting 

Let's go to the folder with Squid

    cd /etc/squid/

And enter the following command to create the certificate

    openssl req -new -newkey rsa:1024 -days 36500 -nodes -x509 -keyout squid.pem -out squid.pem
    
Next, you will need to enter the certificate data. The certificate is valid for 100 years to forget about it for a long time. It is needed only for Proxy.

Now create our list files.

    touch blacklist
    touch whitelist
    cp whitelist whitelist_ssl
    cp blacklist blacklist_ssl

Sites are listed in the form of regular expressions. For example, to unlock mail.ru, open whitelist

    nano whitelist

and add the following expression to it.

    mail\.ru 

Now block Games.Mail.ru. Let's open our blacklist

    nano blacklist

and write the following expression into it

    games\.mail\.ru
    
Since, as a rule, a blacklist blocker is above our white list, when you switch to mail.ru, the site will open as expected (except for pictures, but more on that later), and if you try to switch to Games, Squid us will not let go.

Some sites have many subdomains, subdomains, etc. As, for example, mail.ru stores its images on imgsmail.ru. Regarding other similar sites, you need to open the desired site in any browser (I use Chrome) and, subsequently, the developer tools (in Chrome they are called by pressing F12).

Go to the Sources tab and see what other resources the site loads information from.

After adding sites, copy them to the lists for HTTPS.

    cp whitelist whitelist_ssl
    cp blacklist blacklist_ssl

# List Fill Tip

Now check the configuration.

    squid -k check

If all is well, stop Squid.

    /etc/init.d/squid stop

Rebuild the cache

    squid -z

And run Squid again

    /etc/init.d/squid start

After any changes to lists or Squid configuration, it must be reloaded with the command

    /etc/init.d/squid restart
    
You can also change the access restriction page (works only on HTTP) under the path / usr / share / squid / errors / ~ Russian-1251. Look in the folder for the ERR_ACCESS_DENIED file and edit it. The file syntax is HTML.
    
# Links

* https://habr.com/ru/post/267851/
* https://habr.com/ru/post/473584/
* https://habr.com/ru/post/314718/
* https://habr.com/ru/post/53542/
* https://habr.com/ru/post/136205/
* https://habr.com/ru/post/272733/
