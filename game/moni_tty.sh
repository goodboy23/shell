#!/bin/bash
# 作者：日行一善 <qq：1969679546> <email：1969679546@qq.com>
# 官网：www.linkops.cn
#
# 日期：2018/6/23
# 介绍：加一层shell终端
#
# 适用：centos6+
# 语言：中文
#
# 注意：无



# 捕获结束信号丢弃，开启后，将无法ctl +c退出
#trap "" HUP INT QUIT TSTP
clear
echo
cat /etc/system-release
echo "Kernel $(uname -r) on an $(uname -m)"
echo


name=`hostname`
while [ 1 ]
do
    #将read里按退格键^H转换为正常的
    stty erase ^h
    read -p "$(hostname) login: " USER
    read -sp "Password: " PASSWD
    echo

    while [ 1 ]
    do
        read -p "[$USER@${name}${PWD}]:" BIN
        $BIN
    done
done

# 重新执行脚本
sh $0