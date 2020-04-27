#!/bin/bash

# 2019-09-05
# 部署MinDoc文档管理系统
# 参考：https://www.iminho.me/wiki/docs/mindoc/mindoc-summary.md

# 安装MySQL
function install_mysql57(){
	# 更新源
	yum install -y epel-release
	# 安装依赖包
	yum install -y  gcc gcc-c++ cmake ncurses ncurses-devel bison
	# axel：多线程下载工具，下载文件时可以替代curl、wget。（人家分享的命令，试试看好不好用）
	yum install -y axel
	# axel -n 20 下载链接
	[ ! -d /opt/software ] && mkdir -p /opt/software
	cd /opt/software
	# 好像有个bug，如果文件遇到特许情况没有下载完成，文件名还是存在的，所以它不会继续下载
	# wget -c 应该可以解决（-c 断点续传）
	# wget -c https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-boost-5.7.25.tar.gz
	[ ! -f mysql-boost-5.7.25.tar.gz ] && axel -n 20 https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-boost-5.7.25.tar.gz
	# 添加用户
	[ ! $(grep mysql /etc/passwd) ] && useradd -s /sbin/nologin mysql
	# 建立所需目录并更改所有者为mysql
	[ ! -d /data/mysql/data ] && mkdir -p /data/mysql/data
	chown -R mysql:mysql /data/mysql
	# 解压
	tar -zxvf mysql-boost-5.7.25.tar.gz
	# 编译安装
	cd /opt/software/mysql-5.7.25/
	# 安装到/opt/mysql目录下
	[ ! -d /opt/mysql ] && mkdir -p /opt/mysql/
	cmake -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_BOOST=boost -DCMAKE_INSTALL_PREFIX=/opt/mysql/
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

basedir = /opt/mysql/
datadir = /data/mysql/data/
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
	chown -R mysql:mysql /opt/mysql
	# 初始化mysql
	cd /opt/mysql/bin
	./mysqld --initialize-insecure --user=mysql --basedir=/opt/mysql --datadir=/data/mysql/data
	# 拷贝可执行配置文件
	cp /opt/mysql/support-files/mysql.server /etc/init.d/mysqld
	# 启动MySQL
	service mysqld start
	# 软连接
	ln -s /opt/mysql/bin/mysql /usr/bin/mysql
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

function mindoc_install(){
	#下载
	[ ! -d /opt/mindoc ] && mkdir -p /opt/mindoc
	cd /opt/mindoc
	wget -c https://github.com/lifei6671/mindoc/releases/download/v2.0/mindoc_linux_amd64.zip
	#解压
	yum install -y unzip
	unzip mindoc_linux_amd64.zip
	# 创建数据库
	USER="root"
	PASSWORD="123"
	GRANT_COMMAND="GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${PASSWORD}' WITH GRANT OPTION;"
	FLUSH_COMMAND="FLUSH PRIVILEGES"
	CREATE_DATABASE_COMMAND="CREATE DATABASE mindoc_db DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_general_ci;"
	# 授权远程登录
	mysql -u${USER} -p${PASSWORD} -e "${GRANT_COMMAND}"
	mysql -u${USER} -p${PASSWORD} -e "${FLUSH_COMMAND}"
	# 创建数据库
	mysql -u${USER} -p${PASSWORD} -e "${CREATE_DATABASE_COMMAND}"
	# 配置数据库
	/bin/cp conf/app.conf.example conf/app.conf

	# 将配置文件里的信息换成想要的信息
	# db_adapter="${MINDOC_DB_ADAPTER||sqlite3}"
	# db_host="${MINDOC_DB_HOST||127.0.0.1}"
	# db_port="${MINDOC_DB_PORT||3306}"
	# db_database="${MINDOC_DB_DATABASE||./database/mindoc.db}"
	# db_username="${MINDOC_DB_USERNAME||root}"
	# db_password="${MINDOC_DB_PASSWORD||123456}"

	# 替换
	sed -i 's/db_adapter="${MINDOC_DB_ADAPTER||sqlite3}"/db_adapter="${MINDOC_DB_ADAPTER||mysql}"/' conf/app.conf
	sed -i 's/db_database="${MINDOC_DB_DATABASE||\.\/database\/mindoc\.db}"/db_database="${MINDOC_DB_DATABASE||mindoc_db}"/' conf/app.conf
	sed -i 's/db_password="${MINDOC_DB_PASSWORD||123456}"/db_password="${MINDOC_DB_PASSWORD||123}"/' conf/app.conf
	# 初始化数据库
	./mindoc_linux_amd64 install
	#修改可执行权限
	chmod +x mindoc_linux_amd64
	#启动程序
	nohup ./mindoc_linux_amd64 > mindoc.log 2>&1 &

	echo -e "\033[31m日志文件在：/opt/mindoc/mindoc.log\033[0m"
	echo -e "\033[31m访问链接：http://IP地址:8181\033[0m"
	echo -e "\033[31m账号：admin\033[0m"
	echo -e "\033[31m密码：123456\033[0m"
}

function main(){
	install_mysql57
	mindoc_install
}

main
