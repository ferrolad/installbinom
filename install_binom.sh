#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run one-click installation, please switch to root and try again"
    exit 1
fi

#define the current directory
cur_dir=`pwd`

#define the software version

mysql_ver="5.5.47"
php_ver="5.5.30"
nginx_ver="1.6.3"
phpmyadmin_ver="4.5.5.1"

#clear the screen
clear

echo "====================================================================================================================================="
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! WARNING !!!"
echo "! Make sure you are running one-click installation on a fresh new server without any php, mysql and web server !"
echo "! otherwise, the one-click installation will uninstall any existing php, mysql and webserver, which may kill some web based console !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo ""
echo "One-click binom installation script"
echo ""
echo "Softwares will be installed:"
echo "MySQL: ${mysql_ver}"
echo "PHP: ${php_ver}"
echo "Nginx: ${nginx_ver}"
echo "PHPMyAdmin: ${phpmyadmin_ver}"
echo "PHP Zend Opcache Extension"
echo "Latest ionCude Loader"
echo "Latest Binom tracking software"
echo "====================================================================================================================================="
echo ""

#set mysql root password
mysqlrootpwd="root"
echo "Enter the root password of MySQL:"
read -p "(Default password: root):" mysqlrootpwd
if [ "$mysqlrootpwd" = "" ]; then
	mysqlrootpwd="root"
fi
echo ""

#set tracking domain
tracking_domain="www.example.com"
echo "Enter your domain name for tracking:"
read -p "(for example: www.example.com):" tracking_domain
if [ "$tracking_domain" = "" ]; then
	tracking_domain="www.example.com"
fi
echo ""

#generate a random string, which is used for php-fpm status page location
status_page_id=`cat /proc/sys/kernel/random/uuid | md5sum | cut -d ' ' -f1`

get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}

echo "========================================"
echo "Your Installation Details:"
echo ""
echo "MySQL root password: ${mysqlrootpwd}"
echo "Domain for tracking: ${tracking_domain}"
echo "========================================"
echo ""
echo "Press any key to start, or ctrl+z to stop at anytime..."
char=`get_char`

#initiate install
function InitInstall() {
#server information, which is used for debug
uname -a
allmem=`free -m | grep Mem | awk '{print  $2}'`
echo "Memory: ${allmem} MB"

#remove installed software
service mysql stop
service php-fpm stop
service nginx stop
/bin/rm -rf /webserv

#remove if any
rpm -qa|grep httpd
rpm -e httpd
rpm -qa|grep mysql
rpm -e mysql
rpm -qa|grep php
rpm -e php

yum -y remove httpd*
yum -y remove php*
yum -y remove mysql-server mysql mysql-libs

yum -y install yum-fastestmirror

#disable seLinux
if [ -s /etc/selinux/config ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

#install dependencies
yum -y install ntp wget patch make cmake gcc ncurses ncurses-devel gcc-c++ autoconf libtool libtool-libs automake bison kernel kernel-devel openssl openssl-devel flex libxml2 libxml2-devel curl curl-devel libjpeg libjpeg-devel libpng libpng-devel gd gd-devel freetype freetype-devel zlib zlib-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel unzip gettext gettext-devel

#update ntp
ntpdate -u pool.ntp.org
date

#add user and group
groupadd www
useradd -s /sbin/nologin -M -g www www
groupadd mysql
useradd -s /sbin/nologin -M -g mysql mysql

#make dir for webservers
mkdir -p /webserv/mysql
mkdir /webserv/php
mkdir /webserv/nginx
mkdir /webserv/logs

#make dir for web
mkdir -p /web/www

#make dir for sock file
mkdir /webserv/var
chmod 777 /webserv/var
chmod +t /webserv/var

#install package
cd ${cur_dir}
#libiconv http://ftp.gnu.org/gnu/libiconv/
if [ ! -s libiconv-1.15.tar.gz ]; then
	wget -c http://ftp.gnu.org/gnu/libiconv/libiconv-1.15.tar.gz
fi
tar -zxf libiconv-1.15.tar.gz
cd libiconv-1.15/
./configure
make && make install

cd ${cur_dir}
#libmcrypt http://sourceforge.net/projects/mcrypt/files/Libmcrypt/
if [ ! -s libmcrypt-2.5.8.tar.gz ]; then
	wget -c "https://jaist.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz"
fi
tar -zxf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8/
./configure
make && make install
/sbin/ldconfig
cd libltdl/
./configure --enable-ltdl-install
make && make install

cd ${cur_dir}
#mhash http://sourceforge.net/projects/mhash/files/mhash/
if [ ! -s mhash-0.9.9.9.tar.gz ]; then
	wget -c "https://jaist.dl.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz"
fi
tar -zxf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9/
./configure
make && make install

cd ${cur_dir}
#mcrypt http://sourceforge.net/projects/mcrypt/files/MCrypt/
if [ ! -s mcrypt-2.6.8.tar.gz ]; then
	wget -c "https://jaist.dl.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz"
fi
tar -zxf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8/
./configure
make && make install

#add symbolic link
ln -fs /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
ln -fs /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
ln -fs /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
ln -fs /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
ln -fs /usr/local/lib/libmhash.a /usr/lib/libmhash.a
ln -fs /usr/local/lib/libmhash.la /usr/lib/libmhash.la
ln -fs /usr/local/lib/libmhash.so /usr/lib/libmhash.so
ln -fs /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
ln -fs /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1

if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
	ln -fs /usr/lib64/libpng.* /usr/lib/
	ln -fs /usr/lib64/libjpeg.* /usr/lib/
fi

ulimit -v unlimited
ulimit -n 65535

#add lib
if [ ! `grep -l "/lib" '/etc/ld.so.conf'` ]; then
	echo "/lib" >> /etc/ld.so.conf
fi

if [ ! `grep -l '/usr/lib' '/etc/ld.so.conf'` ]; then
	echo "/usr/lib" >> /etc/ld.so.conf
fi

if [ -d "/usr/lib64" ] && [ ! `grep -l '/usr/lib64' '/etc/ld.so.conf'` ]; then
	echo "/usr/lib64" >> /etc/ld.so.conf
fi

if [ -d "/lib64" ] && [ ! `grep -l '/lib64' '/etc/ld.so.conf'` ]; then
	echo "/lib64" >> /etc/ld.so.conf
fi

if [ ! `grep -l '/usr/local/lib' '/etc/ld.so.conf'` ]; then
	echo "/usr/local/lib" >> /etc/ld.so.conf
fi

/sbin/ldconfig

#optimize the os limits
cat >> /etc/security/limits.conf <<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

echo "fs.file-max=65535" >> /etc/sysctl.conf

}

function InstallMysql()
{
echo "+------------------+"
echo "| Installing MySQL |"
echo "+------------------+"
cd ${cur_dir}
if [ ! -s mysql-${mysql_ver}.tar.gz ]; then
	wget -c http://dev.mysql.com/get/Downloads/MySQL-5.5/mysql-${mysql_ver}.tar.gz
else
	/bin/rm -rf mysql-${mysql_ver}
fi
tar -zxf mysql-${mysql_ver}.tar.gz
cd mysql-${mysql_ver}
cmake -DCMAKE_INSTALL_PREFIX=/webserv/mysql -DMYSQL_DATADIR=/webserv/mysql/data -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=none -DMYSQL_UNIX_ADDR=/webserv/var/mysql.sock -DENABLED_LOCAL_INFILE=1 -DWITH_EMBEDDED_SERVER=1
make && make install
cd ..

#copy mysql config file
/bin/cp -f /webserv/mysql/support-files/my-large.cnf /etc/my.cnf
sed -i 's#skip-external-locking#skip-external-locking\nlog-error = /webserv/logs/mysql.log\ndefault-storage-engine=MyISAM#g' /etc/my.cnf
sed -i 's#log-bin=mysql-bin#log-bin=mysql-bin\nmax_binlog_size=512M\nexpire_logs_days=3#g' /etc/my.cnf

#add binom config
cat > /etc/my.cnf.d/binom.conf <<eof
[mysqld]
table_definition_cache=1600
open_files_limit=5000
event_scheduler=ON
max_heap_table_size=2147483648
eof

#change owner and install basic db
chown -R mysql:mysql /webserv/mysql/.
/webserv/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/webserv/mysql --datadir=/webserv/mysql/data --user=mysql
chown -R root /webserv/mysql/.
chown -R mysql /webserv/mysql/data

#add mysql to os service
/bin/cp -f /webserv/mysql/support-files/mysql.server /etc/init.d/mysql
chmod +x /etc/init.d/mysql
chkconfig --add mysql
chkconfig --level 2345 mysql on

#add mysql lib
if [ ! `grep -l '/webserv/mysql/lib' '/etc/ld.so.conf'` ]; then
	echo "/webserv/mysql/lib" >> /etc/ld.so.conf
fi
/sbin/ldconfig

#add symbolic link
ln -fs /webserv/mysql/lib/mysql /usr/lib/mysql
ln -fs /webserv/mysql/include/mysql /usr/include/mysql
ln -fs /webserv/mysql/bin/mysql /usr/bin/mysql
ln -fs /webserv/mysql/bin/mysqldump /usr/bin/mysqldump
ln -fs /webserv/mysql/bin/myisamchk /usr/bin/myisamchk
ln -fs /webserv/mysql/bin/mysqld_safe /usr/bin/mysqld_safe

/etc/init.d/mysql start

#delete the dangerous user
/webserv/mysql/bin/mysqladmin -u root password ${mysqlrootpwd}
cat > /tmp/mysql_temp_script <<eof
use mysql;
update user set password=password('${mysqlrootpwd}') where user='root';
delete from user where user!='root';
delete from user where password='';
delete from user where host!='localhost'; 
DROP USER ''@'%';
flush privileges;
create database if not exists binom;
eof
/webserv/mysql/bin/mysql -u root -p${mysqlrootpwd} -h localhost < /tmp/mysql_temp_script
/bin/rm -f /tmp/mysql_temp_script
}


function InstallPHP()
{
echo "+----------------+"
echo "| Installing PHP |"
echo "+----------------+"
cd ${cur_dir}
if [ ! -s php-${php_ver}.tar.gz ]; then
	wget -c http://php.net/distributions/php-${php_ver}.tar.gz
else
	/bin/rm -rf php-${php_ver}
fi
tar -zxf php-${php_ver}.tar.gz
cd php-${php_ver}
./configure --prefix=/webserv/php --with-config-file-path=/webserv/php/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-opcache --with-mysql=/webserv/mysql --with-mysql-sock=/webserv/var/mysql.sock --with-mysqli=/webserv/mysql/bin/mysql_config --with-pdo-mysql=/webserv/mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-curl --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --with-libxml-dir=/usr --enable-xml --without-pear --enable-zip --disable-fileinfo
make ZEND_EXTRA_LIBS='-liconv'
make install

ln -fs /webserv/php/bin/php /usr/bin/php
ln -fs /webserv/php/bin/phpize /usr/bin/phpize
ln -fs /webserv/php/sbin/php-fpm /usr/bin/php-fpm

# Modifying php.ini
/bin/cp -f php.ini-production /webserv/php/etc/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 16M/g' /webserv/php/etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 16M/g' /webserv/php/etc/php.ini
sed -i 's#;upload_tmp_dir =#upload_tmp_dir = "/tmp"#g' /webserv/php/etc/php.ini
sed -i 's/;date.timezone =/date.timezone = UTC/g' /webserv/php/etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /webserv/php/etc/php.ini
sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /webserv/php/etc/php.ini
sed -i 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' /webserv/php/etc/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /webserv/php/etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 900/g' /webserv/php/etc/php.ini
sed -i 's/register_long_arrays = On/;register_long_arrays = On/g' /webserv/php/etc/php.ini
sed -i 's/error_reporting = .*/error_reporting = E_ALL \& \~E_NOTICE/g' /webserv/php/etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/g' /webserv/php/etc/php.ini
sed -i 's/disable_functions =.*/disable_functions = passthru,shell_exec,exec,system,chroot,chgrp,chown,proc_open,stream_socket_server,proc_get_status,symlink,ini_alter,ini_restore,dl,openlog,syslog,readlink,popepassthru/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.enable=.*$/opcache.enable=1/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.memory_consumption=.*$/opcache.memory_consumption=128/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.interned_strings_buffer=.*$/opcache.interned_strings_buffer=16/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.max_accelerated_files=.*$/opcache.max_accelerated_files=4000/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.max_wasted_percentage=.*$/opcache.max_wasted_percentage=5/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.validate_timestamps=.*$/opcache.validate_timestamps=0/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.save_comments=.*$/opcache.save_comments=0/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.load_comments=.*$/opcache.load_comments=0/g' /webserv/php/etc/php.ini
sed -i 's/^;opcache.fast_shutdown=.*$/opcache.fast_shutdown=1/g' /webserv/php/etc/php.ini

# add php-fpm.conf
cat > /webserv/php/etc/php-fpm.conf <<eof
[global]
pid = /webserv/php/var/run/php-fpm.pid
error_log = /webserv/logs/php.log
log_level = notice

[www]
listen = /webserv/var/php-cgi.sock
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
request_terminate_timeout = 3600
#pm = dynamic
pm = ondemand
#pm.max_children = 30
pm.max_children = 1000
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 5
pm.status_path = /panel/php-status-${status_page_id}
catch_workers_output = yes

pm.process_idle_timeout = 10s
pm.max_requests = 0
chdir = /
eof

echo "+---------------------------+"
echo "| Installing ioncube loader |"
echo "+---------------------------+"
if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
    cd /usr/local/
	wget -c http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
	tar -zxf ioncube_loaders_lin_x86-64.tar.gz
else
    cd /usr/local/
	wget -c http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz
	tar -zxf ioncube_loaders_lin_x86.tar.gz
fi

php_ext_dir=`/webserv/php/bin/php -r "echo ini_get('extension_dir');"`

/bin/cp -f /usr/local/ioncube/ioncube_loader_lin_5.5.so ${php_ext_dir}/ioncube_loader_lin_5.5.so

cat >> /webserv/php/etc/php.ini <<eof
zend_extension=${php_ext_dir}/ioncube_loader_lin_5.5.so
zend_extension=${php_ext_dir}/opcache.so
eof

/bin/rm -f /usr/local/ioncube_loaders_lin_*

#add php to os service
/bin/cp -f ${cur_dir}/php-${php_ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig --level 2345 php-fpm on
service php-fpm start
}

function InstallPMA() {
	if [ ! -d /web/www/$tracking_domain ]; then
		mkdir /web/www/$tracking_domain
	else
		/bin/rm -rf /web/www/$tracking_domain/*
	fi
	cd /web/www/${tracking_domain}
	#install phpmyadmin
	/bin/rm -f /web/www/${tracking_domain}/pma
	cd /web/www/${tracking_domain}
	wget -c --no-check-certificate https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_ver}/phpMyAdmin-${phpmyadmin_ver}-all-languages.tar.gz
	tar -zxf phpMyAdmin-${phpmyadmin_ver}-all-languages.tar.gz
	mv phpMyAdmin-${phpmyadmin_ver}-all-languages pma
	/bin/rm -f phpMyAdmin-${phpmyadmin_ver}-all-languages.tar.gz
}

function InstallBinom(){
	if [ ! -d /web/www/$tracking_domain ]; then
		mkdir /web/www/$tracking_domain
	else
		/bin/rm -rf /web/www/$tracking_domain/*
	fi

	cd /web/www/${tracking_domain}
	wget -P /web/www/${tracking_domain} binom.org/download/Install_Binom_Latest.tar.gz
	tar -xzf /web/www/${tracking_domain}/Install_Binom_Latest.tar.gz -C /web/www/${tracking_domain}
	rm /web/www/${tracking_domain}/Install_Binom_Latest.tar.gz

	chown -R www /web/www/${tracking_domain}/
	chmod -R 755 /web/www/${tracking_domain}/
}

function InstallNginx() {
echo "+------------------+"
echo "| Installing Nginx |"
echo "+------------------+"
cd ${cur_dir}

#pcre http://sourceforge.net/projects/pcre/files/pcre/
if [ ! -s pcre-8.40.tar.gz ]; then
	wget -c "https://nchc.dl.sourceforge.net/project/pcre/pcre/8.40/pcre-8.40.tar.gz"
fi
tar -zxf pcre-8.40.tar.gz

#zlib http://sourceforge.net/projects/libpng/files/zlib/
if [ ! -s zlib-1.2.11.tar.gz ]; then
	wget -c "https://nchc.dl.sourceforge.net/project/libpng/zlib/1.2.11/zlib-1.2.11.tar.gz"
fi
tar -zxf zlib-1.2.11.tar.gz

/sbin/ldconfig

#nginx
cd ${cur_dir}
if [ ! -s nginx-${nginx_ver}.tar.gz ]; then
	wget -c http://nginx.org/download/nginx-${nginx_ver}.tar.gz
else
	/bin/rm -rf nginx-${nginx_ver}
fi

tar -zxf nginx-${nginx_ver}.tar.gz
cd nginx-${nginx_ver}
./configure --prefix=/webserv/nginx --user=www --group=www --error-log-path=/webserv/logs/nginx.err --with-pcre=../pcre-8.40 --with-zlib=../zlib-1.2.11 --with-pcre-jit --with-http_ssl_module --with-http_gzip_static_module --with-ipv6 --with-http_stub_status_module
make && make install

cpu_num=`cat /proc/cpuinfo | grep "^processor" | wc -l`
cpu_cores=$[ $cpu_num*2 ]

#add nginx conf file
/bin/rm -f /webserv/nginx/conf/nginx.conf
cat > /webserv/nginx/conf/nginx.conf <<eof
user www www;

#worker_processes  ${cpu_cores};
worker_processes auto;

error_log /webserv/logs/nginx.err crit;

pid /webserv/var/nginx.pid;

worker_rlimit_nofile 65535;

events {
	use epoll;
	worker_connections  65535;
	multi_accept on;
}

http {
	include       mime.types;
	default_type  application/octet-stream;

	access_log off;
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	server_tokens off;
	types_hash_max_size 2048;

	keepalive_timeout  65;
	
	#gzip
	gzip on;
	gzip_min_length  1024;
	gzip_buffers     4 8k;
	gzip_comp_level 3;
	gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
	gzip_vary on;
	gzip_proxied        expired no-cache no-store private auth;
	gzip_disable        "MSIE [1-6]\.";
	
	send_timeout 3600;

	#fastcgi
	fastcgi_connect_timeout 300;
	fastcgi_send_timeout 3600;
	fastcgi_read_timeout 3600;
	fastcgi_buffer_size 128k;
	fastcgi_buffers 64 128k;
	fastcgi_busy_buffers_size 128k;
	fastcgi_temp_file_write_size 128k;
	
	#client size
	client_max_body_size 16m;
	client_body_buffer_size 128k;
	client_header_buffer_size 128k;
	large_client_header_buffers 64 128k;
	
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;
	
	
	#server without any domain
	server {
       	listen	80;
       	server_name	_;
		return	404;
	}
	include vhosts/*.conf;
}
eof

if [ ! -d "/webserv/nginx/conf/vhosts" ]; then
	mkdir /webserv/nginx/conf/vhosts
fi

cat > /webserv/nginx/conf/vhosts/${tracking_domain}.conf <<eof
server {
   	listen 80;
	server_name ${tracking_domain};
	index index.php index.html;
	root /web/www/${tracking_domain};
	access_log   off;
	try_files \$uri \$uri/ =404;

	location ~ \\.php\$ {
		#try_files \$uri =404;
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass unix:/webserv/var/php-cgi.sock;
		fastcgi_index index.php;
		include /webserv/nginx/conf/fastcgi.conf;
		#include fastcgi_params;
	}

	location ~ \\.(jpg|png|gif|ico|swf|js|css|eot|svg|ttf|woff)\$ {
		expires 30d;
	}

	location ~ \\.(js|css)?\$ {
		expires 30d;
	}

	#php-fpm status page
	location /panel/php-status-${status_page_id} {
		fastcgi_pass unix:/webserv/var/php-cgi.sock;
		fastcgi_index index.php;
		include /webserv/nginx/conf/fastcgi.conf;
	}
	
	#nginx status page
	location /panel/nginx-status-${status_page_id} {
		stub_status on;
	}
}
eof

#add link
ln -fs /webserv/nginx/sbin/nginx /usr/bin/nginx

#add nginx service
cat > /etc/init.d/nginx <<eof
#! /bin/sh

### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts nginx
# Description:       starts the nginx web server daemon
### END INIT INFO

prefix=/webserv/nginx
nginx_bin=\${prefix}/sbin/nginx
conf_file=\${prefix}/conf/nginx.conf
pid_file=/webserv/var/nginx.pid
initd_file=/etc/init.d/nginx

case "\$1" in
	start)
		echo -n "Starting Nginx..."

		if [ -s \${pid_file} ]; then
			echo "Nginx (pid \`pidof nginx\`) already running."
			exit 1
		fi

		\$nginx_bin -c \$conf_file

		if [ "\$?" != 0 ]; then
			echo "failed"
			exit 1
		else
			echo "done"
		fi
	;;

	stop)
		echo -n "Stoping Nginx..."

		if [ ! -s \${pid_file} ]; then
			echo "Nginx is not running."
			exit 1
		fi

		\$nginx_bin -s stop

		if [ "\$?" != 0 ] ; then
			echo "failed. You can use force-quit instead"
			exit 1
		else
			echo "done"
		fi
	;;

	status)
		if [ -s \${pid_file} ]; then
			echo "Nginx (pid \`pidof nginx\`) is running."
		else
			echo "Nginx is not running."
			exit 0
		fi
	;;

	force-quit)
		echo -n "Terminating Nginx... "

		if [ ! -s \${pid_file} ]; then
			echo "Nginx is not running."
			exit 1
		fi

		kill -TERM \`cat \${pid_file}\`

		if [ "\$?" != 0 ] ; then
			echo "failed"
			exit 1
		else
			echo "done"
		fi
	;;

	restart)
		\$initd_file stop
		\$initd_file start
	;;

	reload)

		echo "Reloading Nginx..."

		if [ -s \${pid_file} ]; then
			\$nginx_bin -s reload
			echo "done"
		else
			echo -n "Nginx is not running..."
			\$initd_file start
		fi
	;;

	*)
		echo "Usage: service nginx {start|stop|force-quit|restart|reload|status}"
		exit 1
	;;

esac
eof

echo "testing nginx..."
nginx -t

chmod +x /etc/init.d/nginx
chkconfig --add nginx
chkconfig --level 2345 nginx on
service nginx start
}

#show installation details
function showDetails() {
#check if port 80 is opened
#if [! `grep -l '/etc/sysconfig/iptables'    'dport 80 -j ACCEPT'`]; then
#	iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
#	/etc/init.d/iptables save
#	service iptables restart
#fi
echo "===================================================================================================="
echo "| Installation accomplished! Details:"
echo "|"
echo "| Tracking domain: http://${tracking_domain}"
echo "| MySQL root password: ${mysqlrootpwd}"
echo "| PHPMyAdmin Url: ${tracking_domain}/pma/"
echo "| Domain folder: /web/www/${tracking_domain}"
echo "| Nginx config: /webserv/nginx/conf/nginx.conf"
echo "| Domain config: /webserv/nginx/conf/vhosts/${tracking_domain}.conf"
echo "|"
echo "| Now go to http://${tracking_domain} and finish Binom installation."
echo "===================================================================================================="
}

#start install
InitInstall
InstallMysql
InstallPHP
InstallPMA
InstallBinom
InstallNginx
showDetails
