#!/bin/bash

# 2019-08-27
# 源码编译LNMP(CentOS7.6+Nginx1.15+MySQL5.7+PHP7.3)

# 参考:https://www.cnblogs.com/baorong/p/9166417.html
# 参考：https://blog.csdn.net/zhang_referee/article/details/88212695

function install_nginx(){
	# 更新epel源
	yum install -y epel-release
	# 安装依赖包
	yum -y install gcc gcc-c++ autoconf automake zlib zlib-devel openssl openssl-devel pcre*
	# 创建nginx运行用户
	# -M(不创建主目录) -s（不允许登录）
	[ ! $(grep nginx /etc/passwd) ] && useradd -M -s /sbin/nologin nginx
	cd /usr/local/src/
	# 下载pcre源码包
	wget -c https://jaist.dl.sourceforge.net/project/pcre/pcre/8.42/pcre-8.42.tar.gz
	tar -zxvf pcre-8.42.tar.gz
	# 下载nginx源码包
	wget -c http://nginx.org/download/nginx-1.15.0.tar.gz
	tar -zxvf nginx-1.15.0.tar.gz
	cd /usr/local/src/nginx-1.15.0/
	# 编译安装
	./configure --prefix=/usr/local/nginx --with-pcre=/usr/local/src/pcre-8.42 --with-http_ssl_module --user=nginx --group=nginx

	make && make install

	# 启动
	/usr/local/nginx/sbin/nginx
	# 输出版本
	/usr/local/nginx/sbin/nginx	-v
	[ $? -eq 0 ] && echo -e "\033[31mNginx安装成功\033[0m"
	sleep 10
}

function install_mysql57(){
	# 更新源
	yum install -y epel-release
	# 安装依赖包
	yum install -y gcc gcc-c++ cmake ncurses ncurses-devel bison
	# axel：多线程下载工具，下载文件时可以替代curl、wget。（人家分享的命令，试试看好不好用）
	yum install -y axel
	# axel -n 20 下载链接
	cd /usr/local/src
	# 好像有个bug，如果文件遇到特许情况没有下载完成，文件名还是存在的，所以它不会继续下载
	# wget -c 应该可以解决（-c 断点续传）
	# wget -c https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-boost-5.7.25.tar.gz
	[ ! -f mysql-boost-5.7.25.tar.gz ] && axel -n 20 https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-boost-5.7.25.tar.gz
	# 添加用户
	[ ! $(grep mysql /etc/passwd) ] && useradd -s /sbin/nologin mysql
	# 建立所需目录并更改所有者为mysql
	[ ! -d /data/mysql/data ] && mkdir -p /data/mysql/data
	chown -R mysql:mysql /data/mysql
	# 将下载好的mysql 解压到/usr/local/mysql 目录下
	[ ! -d /usr/local/mysql/ ] && mkdir -p /usr/local/mysql/
	tar -zxvf mysql-boost-5.7.25.tar.gz -C /usr/local/mysql/
	# 编译安装
	cd /usr/local/mysql/mysql-5.7.25/
	# cmake安装MySQL默认安装在/usr/local/mysql，如果要指定目录需要加参数：-DCMAKE_INSTALL_PREFIX=
	cmake -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_BOOST=boost
	make -j 2 && make install
# 配置文件
cat > /etc/my.cnf << \EOF
[client]
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
user = mysql

basedir = /usr/local/mysql
datadir = /data/mysql/data
pid-file = /data/mysql/mysql.pid

log_error = /data/mysql/mysql-error.log
slow_query_log = 1
long_query_time = 1
slow_query_log_file = /data/mysql/mysql-slow.log

skip-external-locking
key_buffer_size = 32M
max_allowed_packet = 1024M
table_open_cache = 128
sort_buffer_size = 768K
net_buffer_length = 8K
read_buffer_size = 768K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 16
query_cache_size = 16M
tmp_table_size = 32M
performance_schema_max_table_instances = 1000

explicit_defaults_for_timestamp = true
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log_bin=mysql-bin
binlog_format=mixed
server_id   = 232
expire_logs_days = 10
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_file_per_table = 1
innodb_buffer_pool_size = 128M
innodb_log_file_size = 32M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 32M
sort_buffer_size = 768K
read_buffer = 2M
write_buffer = 2M

EOF

	# 修改文件目录属主属组
	chown -R mysql:mysql /usr/local/mysql
	# 初始化mysql
	cd /usr/local/mysql/bin
	./mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql/data
	# 拷贝可执行配置文件
	cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
	# 启动MySQL
	service mysqld start
	# 软连接
	ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
	# 设置开机自启动
	systemctl enable mysqld

	# 修改密码
	mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123';"
	[ $? -eq 0 ] && echo -e "\033[31mMySQL安装成功\033[0m" && echo -e "\033[31mMySQL的初始密码为：123\033[0m"
	sleep 10

	# 授权远程登录
	# GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123' WITH GRANT OPTION;
	# mysql -uroot -p123 -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123' WITH GRANT OPTION;"
	# FLUSH PRIVILEGES;
	# mysql -uroot -p123 -e "FLUSH PRIVILEGES;"
}

function install_php(){
	# 安装依赖
	yum install -y gcc gcc-c++ php-mcrypt libmcrypt libmcrypt-devel autoconf freetype gd libmcrypt \
	libpng libpng-devel libjpeg libxml2 libxml2-devel zlib curl curl-devel re2c net-snmp-devel \
	libjpeg-devel php-ldap openldap-devel openldap-servers openldap-clients freetype-devel gmp-devel
	# 下载php源码包
	cd /usr/local/src/
	wget -c https://www.php.net/distributions/php-7.3.8.tar.gz
	tar -zxvf php-7.3.8.tar.gz
	
	# 编译安装
	# 提前解决报错
	cp -frp /usr/lib64/libldap* /usr/lib/

	cd /usr/local/src/
	wget -c https://nih.at/libzip/libzip-1.2.0.tar.gz
	tar -zxvf libzip-1.2.0.tar.gz
	cd libzip-1.2.0
	./configure
	make && make install

	# /etc/ld.so.conf 此文件记录了编译时使用的动态库的路径，也就是加载so库的路径。
cat >> /etc/ld.so.conf << \EOF
/usr/local/lib64
/usr/local/lib
/usr/lib
/usr/lib64
EOF
	# ldconfig -v的作用是将文件/etc/ld.so.conf列出的路径下的库文件缓存到/etc/ld.so.cache以供使用
	ldconfig -v

	cd /usr/local/src/php-7.3.8
	./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-mysqli --with-pdo-mysql \
	--with-mysql-sock=/usr/local/mysql/mysql.sock --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir \
	--with-curl --with-gd --with-gmp --with-zlib --with-xmlrpc --with-openssl --without-pear --with-snmp --with-gettext \
	--with-mhash --with-libxml-dir=/usr --with-ldap --with-ldap-sasl --with-fpm-user=nginx --with-fpm-group=nginx \
	--enable-xml --enable-fpm  --enable-ftp --enable-bcmath --enable-soap --enable-shmop --enable-sysvsem --enable-sockets \
	--enable-inline-optimization --enable-maintainer-zts --enable-mbregex --enable-mbstring --enable-pcntl --enable-zip \
	--disable-fileinfo --disable-rpath --enable-libxml --enable-opcache --enable-mysqlnd

	# 提前解决报错
	cp /usr/local/lib/libzip/include/zipconf.h /usr/local/include/zipconf.h
	sed -i 's/-lcrypto -lcrypt/-lcrypto -lcrypt -llber/' /usr/local/src/php-7.3.8/Makefile

	make && make install
	# 配置文件
	cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.conf
	# 复制php.ini文件
	cp /usr/local/src/php-7.3.8/php.ini-production /usr/local/php/etc/php.ini
	# 启动
	cp /usr/local/src/php-7.3.8/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	chmod +x /etc/init.d/php-fpm 
	chkconfig --add php-fpm
	chkconfig php-fpm on
	[ ! $(grep nginx /etc/passwd) ] && useradd -M -s /sbin/nologin nginx
	service php-fpm start
	[ $? -eq 0 ] && echo -e "\033[31mPHP安装成功\033[0m"
	sleep 10

	# 报错：configure: error: Cannot find ldap libraries in /usr/lib.
	# 解决：cp -frp /usr/lib64/libldap* /usr/lib/
	# 然后再次：./configure ...
	
	# 报错：configure: error: Please reinstall the libzip distributions
	# 解决：yum install -y libzip-devel
	# 然后再次：./configure ...
	
	# 报错：checking for libzip... configure: error: system libzip must be upgraded to version >= 0.11
	#先删除旧版本：yum remove -y libzip
	#下载编译安装
	# cd /usr/local/src/
	# wget -c https://nih.at/libzip/libzip-1.2.0.tar.gz
	# tar -zxvf libzip-1.2.0.tar.gz
	# cd libzip-1.2.0
	# ./configure
	# make && make install
	# 然后再次：./configure ...

	# 报错：configure: error: off_t undefined; check your library configuration
	# 解决：
	#添加搜索路径到配置文件
	# echo '/usr/local/lib64
	# /usr/local/lib
	# /usr/lib
	# /usr/lib64'>>/etc/ld.so.conf
	#然后 更新配置
	# ldconfig -v
	# 然后再次：./configure ...

	# 报错：/usr/local/include/zip.h:59:21: 致命错误：zipconf.h：没有那个文件或目录
	# cp /usr/local/lib/libzip/include/zipconf.h /usr/local/include/zipconf.h
	# 然后再次：make && make install

	# 报错：
	# /usr/bin/ld: ext/ldap/.libs/ldap.o: undefined reference to symbol 'ber_strdup'
	# //usr/lib64/liblber-2.4.so.2: error adding symbols: DSO missing from command line
	# collect2: error: ld returned 1 exit status
	# make: *** [sapi/cli/php] 错误 1
	# 解决：在Makefile文件EXTRA_LIBS后面添加 -llber
	# EXTRA_LIBS = -lcrypt -lzip -lzip -lz -lresolv -lcrypt -lrt -lldap -lgmp -lpng -lz -ljpeg 
	# -lz -lrt -lm -ldl -lnsl -lpthread -lxml2 -lz -lm -ldl -lssl -lcrypto -lcurl -lxml2 -lz -lm 
	# -ldl -lssl -lcrypto -lfreetype -lxml2 -lz -lm -ldl -lnetsnmp -lssl -lssl -lcrypto -lm -lxml2 
	# -lz -lm -ldl -lcrypt -lxml2 -lz -lm -ldl -lxml2 -lz -lm -ldl -lxml2 -lz -lm -ldl -lxml2 -lz 
	# -lm -ldl -lssl -lcrypto -lcrypt -llber
	# 然后再次：make && make install
}

function modify_configuration_files(){
	# 备份nginx配置文件
	mv /usr/local/nginx/conf/nginx.conf{,_`date +%F`.bak}

cat > /usr/local/nginx/conf/nginx.conf << \EOF
user  nginx;
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    server_tokens off;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm index.php;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
        location ~ \.php$ {
            root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /usr/local/nginx/html$fastcgi_script_name;
            include        fastcgi_params;
        }
    }
}
EOF

# 测试界面
cat > /usr/local/nginx/html/index.php << \EOF
<?php
    phpinfo();
?>
EOF

	# 检测配置文件的正确性
	/usr/local/nginx/sbin/nginx -t
	# 重新加载配置文件
	/usr/local/nginx/sbin/nginx -s reload
	# 浏览器访问:本地IP:端口/index.php
	IP=$(ip addr | grep -w inet | grep -v "127.0.0.1" | awk '{print $2}' | awk -F'/' '{print $1}')
	[ $? -eq 0 ] && echo -e "\033[31m浏览器访问：本地IP:端口/index.php\033[0m" && echo -e "\033[31m例如：${IP}/index.php\033[0m" \
	&& echo -e "\033[31m出现php信息,成功！\033[0m"
	sleep 10
}

function main(){
	# 安装服务(如果有某个模块安装成功了,可以注释该模块,执行其他的模块)
	install_nginx
	install_mysql57
	install_php
	# 可选配置文件
	modify_configuration_files
}

main
