#!/bin/bash -

# 设置检测环境变量。
source /etc/profile
export LC_ALL=C
TMP_FILE=/tmp/check_tmp_file

CHECK_ID=$(id|sed -e 's/(.*$//' -e 's/^uid=//')
if [ $CHECK_ID -ne 0 ]
then
    echo -e "\t你不是root用户！！"
exit 0
fi

# 检测信息

cat << EOF
    +-------------------------------------------------------------------+
    |                   检测并收集操作系统信息                          |
    |                                  |
    |                   脚本完成时间：`date +'%Y%m%d'`                          |
    +-------------------------------------------------------------------+
EOF

echo "开始检测时间：$(date|awk '{ print $4}')"
echo "主机名：$(hostname)"
echo "系统连续运行时间：$(uptime|awk -F, '{ print $1,$2 }')"
echo "最后启动时间：$(who -b|awk '{ print $3,$4}')"
echo ''

echo "操作系统信息"
echo "操作系统版本："
/usr/bin/which lsb_release 2>&1> /dev/null
if [ $? -eq 0 ]
then
    echo "$(lsb_release -d|awk -F '\t' '{ print $2 }' 2> /dev/null)"
else
    echo `cat /etc/redhat-release`
    echo "未安装 lsb 相关 rpm 包"
fi

echo "当前启动内核信息："
echo "$(uname -rm)"

echo "已经安装的内核包信息："
echo "$(rpm -qa|grep -i ^kernel-[1-9])"

echo "已经存在的启动文件信息："
echo "$(ls -l /boot/|egrep 'init|vmlin'|awk '{ print $9}')"

echo ""

echo "网络信息"
echo "网络地址："
echo "$(ip addr|grep inet|egrep -v 'inet6|127.0.0.1'|awk '{ print $2 }'|awk -F/ '{ print $1 }')"

cat << EOF
网络地址信息：
$(ifconfig -a)
EOF

echo "网络适配器驱动模块信息："
lspci|egrep 'Ethernet controller|Network controller'|awk '{ print $1}' > $TMP_FILE
while read line1
do
    echo "$(lsmod|grep $(lspci -s $line1 -k|grep 'Kernel driver in use'|awk -F: '{ print $2 }'))"
done < $TMP_FILE
rm -f $TMP_FILE

echo ""

echo "网络适配器绑定信息："
grep -i bond /etc/modprobe* 2>&1> /dev/null
if [ $? -eq 0 ]
then
    lsmod|grep bonding > /dev/null && echo '网络适配器绑定配置正常！'
else
    echo '网络适配器没有绑定配置！'
fi

echo ""

echo '网络连通性测试：'
DROP_NU=$(ping -c 100 $(route|grep UG|grep -i default|awk '{print $2}') -i 0.01|grep 'Destination Host Unreachable'|wc -l)
if [ $DROP_NU -eq 0 ]
then
    echo "网络没有丢包！"
else
    echo "连接错误： $DROP_NU ！"
fi

echo ""

#echo 'RHN 注册信息：'
#RHN_INFO=$(rhn-channel -l 2>&1> /dev/null)
#if [ ${RHN_INFO} -eq 0 ]
#then
#    echo "系统注册到 RHN"
#else
#    echo "系统未注册到 RHN"
#fi

echo ""

echo "系统磁盘信息："
echo "$(fdisk -l 2> /dev/null|grep '^Disk /dev/'|awk -F, '{ print $1 }')"
echo ""

echo "分区空间信息："
echo "$(df -h|grep -vE 'tmpfs|none')"
echo ""

echo "分区 inode 号信息："
echo "$(df -hi|grep -vE 'tmpfs|none')"
echo ""

echo '逻辑卷信息：'
echo "$(uname -r|grep 2.4.9 > /dev/null || lvscan 2> /dev/null)"
echo ''

echo 'UID 是 0 的用户：'
echo "$(awk -F: '$3==0 {print $1}' /etc/passwd)"
echo ''

echo '普通用户列表：'
echo "$(grep -v nobody /etc/passwd|awk -F: '$3>=500 {print $1}')"
echo ''

echo '未设置密码及未锁定用户列表：'
grep -v nobody /etc/passwd|awk -F: '$3>=500 {print $1}' > $TMP_FILE 
while read line1
do
    echo "$(grep $line1 /etc/shadow|grep :!)"
done < $TMP_FILE
rm -f $TMP_FILE
echo ''

echo "最后登录的 10 个用户："
echo "$(last -R|head -n 10)"
echo ''

ROOT_MX=$(ls -l ~/Mail 2> /dev/null|wc -l)
if [ $ROOT_MX -eq 0 ]
then
    echo 'root 用户没有告警邮件！'
else
    echo "root 用户有 $(expr $ROOT_MX - 1) 封告警邮件！"
    echo "$(ls -l ~/Mail)"
fi
echo ''

grep -v nobody /etc/passwd|awk -F: '$3>=500 {print $1}' > $TMP_FILE 
while read line1
do
    echo "用户 $line1 告警邮件："
    echo "$(su - $line1 -c 'ls -l ~/Mail' 2> /dev/null|grep -v 'total')"
done < $TMP_FILE
rm -f $TMP_FILE
echo ''

echo '系统内存/交换空间检测（间隔每3秒）'
echo "$(free -m -s 30 -c2)"
echo ''

echo "CPU使用率信息："
/usr/bin/which lsb_release 2>&1> /dev/null
if [ $? -eq 0 ]
then
    OS_ID=$(lsb_release -r|awk -F '\t' '{ print $2 }'|awk -F. '{ print $1 }' 2> /dev/null)
    if [ $OS_ID -ne 9 ]
    then
        CPU_IDLE=$(top -b -n1|grep -i '^cpu'|awk -F, '{ print $4 }'|awk '{ print $1 }'|awk -F. '{ print $1 }')
        if [[ $CPU_IDLE -ne 0 ]]
        then
            echo "CPU 未使用率 $CPU_IDLE%"
        else
            echo "CPU 未使用率 $(top -b -n1|grep 'total'|awk '{ print $8 }'|awk -F. '{ print $1 }')%"
        fi

    else
        echo "CPU 未使用率 $(top -b -n1|grep -i '^cpu'|awk '{ print $11 }'|awk -F. '{ print $1 }')%"
    fi
else
    echo `cat /etc/redhat-release`
    echo "未安装 lsb 相关 rpm 包"
fi

echo ""

if [[ $CPU_IDLE < 20 ]]
then
    echo "CPU 未使用率 $($CPU_IDLE)% ，使用率 80%+"
fi
echo ''

echo "物理CPU个数： $(cat /proc/cpuinfo|grep "physical id"|sort|uniq|wc -l)"
echo "物理CPU核数： $(cat /proc/cpuinfo|grep "cores"|uniq|awk '{print $4}')"
echo "逻辑CPU个数： $(cat /proc/cpuinfo|grep "processor"|wc -l)"
echo "当前运行模式： $(getconf LONG_BIT)"
CPU_BIT=$(cat /proc/cpuinfo|grep flags|grep ' lm '|wc -l)
if [[ $CPU_BIT > 0 ]]
then
    echo "支持 64 位运算模式"
else
    echo "不支持 64 位运算模式"
fi

echo ''
echo 'CPU 负载信息：'
echo "$(top -b -n2|grep '^Cpu(s):')"
echo ''

Z_PID=$(ps aux|awk '{print $8,$2,$11}'|sed -n '/^Z/p')
IFS=${IFS:3:1}
for pid in $Z_PID
do
    echo "系统中的僵尸进程： $(echo $pid|awk '{print $2,$3}')"
done
echo ''

echo '不可结束进程：'
echo "$(ps -eo pid,stat|grep -i 'stat=d')"
echo ''

echo '占用 CPU 最高的 10 个进程：'
echo "$(ps aux|head -1;ps aux|sort -k3nr|head -10)"
echo ''

echo '占用内存最高的 10 个进程：'
echo "$(ps aux|head -1;ps aux|sort -k4nr|head -10)"
echo ''

cat /boot/grub/grub.conf|grep 'crashkernel=' > /dev/null && echo "$(service kdump status)" || echo '未配置 Kdump 服务！'
echo "$(ls -l /var/crash/dump* 2> /dev/null)"
echo "$(ls -l /root/core.* 2> /dev/null)"
echo ''

echo "当前运行级别：$(runlevel|awk '{ print $2 }')"
echo ''
echo '在 $(runlevel|awk '{ print $2 }') 级别下开机启动服务信息：'
echo "$(chkconfig --list|grep $(runlevel|awk '{ print $2 }'):on)"
echo ''

echo '系统日志信息： /var/log/messages'
echo "$(egrep -i "error|fail|scsi reset|file system full|Warning|token was lost|fencing|rejecting I/O to offline device|segfault|CPU#|Call Trace" /var/log/messages 2> /dev/null)"
echo '系统日志信息： /var/log/secure'
echo "$(egrep -i "error|fail" /var/log/secure 2> /dev/null)"
echo '系统日志信息： /var/log/boot.log'
echo "$(egrep -i "error|fail" /var/log/boot.log 2> /dev/null)"
echo '系统日志信息： /var/log/dmesg'
echo "$(egrep -i "error|fail" /var/log/dmesg 2> /dev/null)"
echo ''

echo "系统级别计划任务："
echo "$(cat /etc/crontab)"
echo ''

echo "root 用户计划任务："
echo "$(crontab -l 2> /dev/null)"
echo ''

grep -v nobody /etc/passwd|awk -F: '$3>=500 {print $1}' > $TMP_FILE 
while read line1
do
    echo "$line1 用户计划任务："
    echo "$(su - $line1 -c 'crontab -l' 2> /dev/null)"
done < $TMP_FILE
rm -f $TMP_FILE
echo ''

echo "$(iostat -x 2> /dev/null || echo 'Sysstat 包没有安装！')"
echo "$(sar -u 3 10 2> /dev/null || echo 'Sysstat 包没有安装！')"
echo "$(sar -w 2> /dev/null || echo 'Sysstat 包没有安装！')"

echo '执行频率最高的 10 个历史命令：'
echo "$(sed -e 's/|/\n/g' ~/.bash_history|cut -d '' -f 1|sort|uniq -c|sort -nr|head)"
echo ''

# RHCS 检测脚本（RHEL4，RHEL5，RHEL6；kernel 2.6.+）：
echo '--------------------------RHCS 检测脚本（RHEL4，RHEL5，RHEL6）-----------------'
echo "$(chkconfig --list|egrep "cman|ccsd|fenced|qdiskd|rgmanager" || echo '没有检测到集群相关服务！')"
echo "$(rpm -qa|egrep 'cman|ccsd|fenced|qdiskd|rgmanager' || echo '未安装集群套件相关 rpm 包！')"
echo '/etc/rc.local 文件内容：'
echo "$(egrep -v '^#|^$' /etc/rc.local)"
echo '/etc/hosts file contents:'
echo "$(egrep -v '^#|^:|^$' /etc/hosts)"
echo '集群当前状态：'
echo "$(clustat 2> /dev/null || echo '没有检测到集群信息！')"
echo "$(mkqdisk -L 2> /dev/null || echo '没有检测到 qdisk 信息！')"
echo "$(service cman status 2>&1)"
echo "$(service ccsd status 2>&1)"
echo "$(service fenced status 2>&1)"
echo "$(service qdiskd status 2>&1)"
echo "$(service rgmanager status 2>&1)"
echo '集群配置文件内容：'
echo "$(cat /etc/cluster/cluster.conf 2> /dev/null || echo '没有找到集群配置文件！')"
echo ''

#openssl 检测脚本 （RHEL4,RHEL5,RHEL6）

echo "search openssl verion:"
rpm -qa ｜ grep openssl
echo "lsof openssl:"
lsof | grep libssl.so 


echo "完成检测时间： $(date|awk '{ print $4}')!"
