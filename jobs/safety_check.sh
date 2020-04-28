#!/usr/bin/bash
# 1---UID和GID为0的非root特权用户检查
newuser_check=`grep "0:0" /etc/passwd | awk -F ':' '{print $1}'`
for i in ${newuser_check};do
    if [[ ${i} != root ]];then
        echo "警告: 系统存在UID和GID为0的非root特权用户${i}"
    else
        echo "安全: 系统中不存在root以外的UID和GID为0的其它特权用户"
    fi
done
# 2---密码为空的用户检查
no_passwd_user=`awk -F: 'length($2)==0 {print $1}' /etc/shadow`
if [[ ${no_passwd_user} == "" ]];then
    echo "安全: 系统中不存在密码为空的用户"
else
    for i in ${no_passwd_user};do
        echo "警告: 用户${i}的密码为空"
    done
fi
# 密码策略检查
pass_max_day=`cat /etc/login.defs | grep PASS_MAX_DAYS | grep -v ^# | awk '{print $2}'`
pass_min_day=`cat /etc/login.defs | grep PASS_MIN_DAYS | grep -v ^# | awk '{print $2}'`
pass_min_len=`cat /etc/login.defs | grep PASS_MIN_LEN | grep -v ^# | awk '{print $2}'`
pass_warn_age=`cat /etc/login.defs | grep PASS_WARN_AGE | grep -v ^# | awk '{print $2}'`
if [[ ${pass_max_day} -ge 90 && ${pass_max_day} != 0 ]];then
    echo "安全: 密码生存周期为${pass_max_day}天，符合密码策略"
else
    echo "警告: 密码生存周期为${pass_max_day}天，不符合密码策略，建议小于90天"
fi
if [[ ${pass_min_day} -ge 7 ]];then
    echo "安全: 密码更改最小时间间隔为${pass_min_day}天，符合密码策略"
else
    echo "警告: 密码更改最小时间间隔为${pass_min_day}天，不符合密码策略，建议大于7天"
fi
if [[ ${pass_min_len} -ge 9 ]];then
    echo "安全: 密码最小长度为${pass_min_len}，符合密码策略"
else
    echo "警告: 密码最小长度为${pass_min_len}，不符合密码策略，建议大于9"
fi
if [[ ${pass_warn_age} -ge 15 ]];then
    echo "安全: 密码过期提醒时间为${pass_warn_age}天，符合密码策略"
else
    echo "警告: 密码过期提醒时间为${pass_warn_age}天，不符合密码策略，建议大于15天"
fi
# grub密码设置检查
grub2_pass_check=`grep 'password_pbkdf2 root' /boot/grub2/grub.cfg | grep -v ^# | awk '{print $3}'`
if [[ ${grub2_pass_check} != '${GRUB2_PASSWORD}' ]];then
    echo "安全: grub2的加密密码已设置"
else
    echo "警告: grub2的加密密码未设置"
fi
# 重要文件权限检查
passwd_file_check=`ls -l /etc/passwd | awk '{print $1}'`
shadow_file_check=`ls -l /etc/shadow | awk '{print $1}'`
group_file_check=`ls -l /etc/group | awk '{print $1}'`
secruretty_file_check=`ls -l /etc/securetty | awk '{print $1}'|awk -F '.' '{print $1}'`
services_file_check=`ls -l /etc/services | awk '{print $1}'|awk -F '.' '{print $1}'`
if [[ ${passwd_file_check} != '-rw-r--r--' ]];then
    echo "警告: 文件passwd的权限当前为${passwd_file_chececk},建议设置为\"-rw-r--r--\""
else
    echo "安全: 文件passwd的权限当前为${passwd_file_chec}，符合安全要求"
fi
if [[ ${shadow_file_check} != '-r--------' ]];then
    echo "警告: 文件shadow的权限当前为${shadow_file_check},建议设置为\"-r--------\""
else
    echo "安全: 文件shadow的权限当前为${shadow_file_check}，符合安全要求"
fi
if [[ ${group_file_check} != '-rw-r--r--' ]];then
    echo "警告: 文件group的权限当前为${group_file_check},建议设置为\"-rw-r--r--\""
else
    echo "安全: 文件group的权限当前为${group_file_check}，符合安全要求"
fi
if [[ ${secruretty_file_check} != '-rw-------' ]];then
    echo "警告: 文件securetty的权限当前为${secruretty_file_check},建议设置为\"-rw-------\""
else
    echo "安全: 文件securetty的权限当前为${secruretty_file_check}，符合安全要求"
fi
if [[ ${services_file_check} != '-rw-r--r--' ]];then
    echo "警告: 文件services的权限当前为${services_file_check},建议设置为\"-rw-r--r--\""
else
    echo "安全: 文件services的权限当前为${services_file_check}，符合安全要求"
fi
# 重要文件防删除更改检查
check_file="/etc/passwd /etc/shadow /etc/gshadow"
for i in ${check_file};do
    flag=0
    for ((x=1;x<=16;x++));do
        character_x=`lsattr ${i} | cut -c $x`
        if [[ ${character_x} == 'i' ]];then
            echo "安全: 文件${i}已设置i的安全属性"
            flag=1
        fi
        if [[ ${character_x} == 'a' ]];then
            echo "安全: 文件${i}已设置a的安全属性"
            flag=1
        fi
    done
    if [[ ${flag} == 0 ]];then
        echo "警告: 文件${i}未设置ai的安全属性，请尽快使用命令\"chattr +i 文件\"与命令\"chattr +a 文件\"进行设置"
    fi
done
# telnet开启检查
telnet_install_check=`ls -l /etc/xinetd.d | grep 'telnet'`
if [[ ${telnet_install_check} != '' ]];then
    echo "消息: telnet服务已安装"
    telnet_open_check=`cat /etc/xinetd.d/telnet | grep disable | awk '{print $3}'`
    if [[ ${telnet_open_check} != 'yes' ]];then
        echo "警告: telnet服务已开启，建议关闭"
    else
        echo "安全: telnet服务未开启"
    fi
else
    echo "消息: telnet服务未安装"
fi
# 3---SSH服务开启与端口安全检查
sshd_check=`netstat -anp | grep sshd | awk '{print $7}'|awk -F '/' '{print $2}' | head -n 1`
ssh_protocol_check=`grep 'Protocol' /etc/ssh/sshd_config | grep -v ^#  | awk '{print $2}'`
sshdport_check=`grep '^Port ' /etc/ssh/sshd_config | awk '{print $2}'`
rootssh_check=`grep '^PermitRootLogin' /etc/ssh/sshd_config | awk '{print $2}'`
ipssh_limit=`grep '[0-9].[0-9].[0-9].[0-9]' /etc/hosts.allow`
if [[ ${sshd_check} != "sshd" ]];then
    echo "消息: 本机ssh服务未开启"
else
    echo "消息: 本机ssh服务已开启"
    if [[ ${sshdport_check} != "22" ]];then
        echo "安全: 本机ssh服务端口已修改为:${sshdport_check}"
    else
        echo "警告: 本机ssh服务端口为默认端口22，请尽快修改"
    fi
    if [[ ${ssh_protocol_check} == '' ]];then
        echo "警告: ssh协议版本未设置，建议设置为版本2"
    elif [[ ${ssh_protocol_check} == '1' ]];then
        echo "警告: ssh2协议版本已设置为1，建议设置为版本2"
    elif [[ ${ssh_protocol_check} == '2' ]];then
        echo "安全: ssh2协议版本已设置为2"
    else
        echo "警告: 请检查脚本命令与ssh配置文件是否正确"
    fi
    if [[ ${rootssh_check} != "yes" ]];then
        echo "安全: 本机ssh服务已禁止root远程登录"
    else
        echo "警告: 本机ssh服务未禁止root远程登录"
    fi
    if [[ ${ipssh_limit} != "" ]];then
        echo "安全: 本机ssh服务已限制远程登录IP地址"
    else
        echo "警告: 本机ssh服务未限制远程登录IP地址"
    fi
fi
# 4---禁用ipv6
ipv6_unenable_check=`grep '^NETWORKING_IPV6=' /etc/sysconfig/network | awk -F '=' '{print $2}'| awk -F '"' '{print $2}'`
if [[ ${ipv6_unenable_check} == "no" ]];then
    echo "安全: 本机已禁用ipv6地址的使用"
else
    echo "警告: 本机未禁用ipv6地址的使用"
fi
# 5---连接数检查
yum -y install mlocate > /dev/null
updatedb
tomcat_check=`locate /server.xml`
if [[ ${tomcat_check} != "" ]];then
    echo "信息: 本机已使用tomcat服务"
    tomcat_port=`grep '<Connector port=' ${tomcat_check} | grep -v '<!--' | grep -v '#' | awk -F '"' '{print $2}'`
    alllink_num=`netstat -ant | grep :${tomcat_port} | wc -l`
    ESTABL_linknum=`netstat -ant | grep $ip:${tomcat_port} | grep EST | wc -l`
    if [[ ${tomcat_port} != "" ]];then
        echo "信息: 本机正在使用的tomcat端口为${tomcat_port}"
        echo "信息: 本机当前总的连接数为${alllink_num}"
        echo "信息: 本机当前有效连接数为${ESTABL_linknum}"
    else
        echo "信息: 未检测到本机使用的tomcat端口"
    fi
else
    echo "信息: 本机未使用tomcat服务"
fi
# 6---僵尸进程检查
process_Z_name=`ps aux | awk '{print $8,$11}'| grep 'Z'| awk '{print $2}'| awk -F '[' '{print $2}'| awk -F ']' '{print $1}'`
process_Z_PID=`ps aux | awk '{print $2,$8,$11}'| grep 'Z'|awk '{print $1}'`
if [[ ${process_Z_name} == "" ]];then
    echo "安全: 系统中不存在僵尸进程"
else
    for i in ${process_Z_name};do
        pkill ${i}
        if [[ $? == 0 ]];then
            echo "安全: 僵尸进程${i}已成功清除"
        else
            echo "警告: 僵尸进程${i}未被清除"
        fi
    done
    for i in ${process_Z_PID};do
        kill -9 ${i}
        if [[ $? == 0 ]];then
            echo "安全: 僵尸进程${i}已成功清除"
        else
            echo "警告: 僵尸进程${i}未被清除"
        fi
    done
fi
# 日志审核开启检查
audit_check=`systemctl status auditd.service | grep 'Active: ' | awk -F '(' '{print $2}'| awk -F ')' '{print $1}'`
if [[ ${audit_check} != 'running' ]];then
    echo "警告: audit日志审计服务未开启"
else
    echo "安全: audit日志审计服务已开启"
fi
# 7---网卡运行模式检查
net_card=`ip link | grep PROMISC`
if [[ ${net_card} != "" ]];then
    echo "警告: 当前网卡运行在混杂模式"
else
    echo "安全: 当前网卡未运行在混杂模式"
fi
# 8---关键系统文件锁定
key_file="/etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/inittab"
for i in ${key_file};do
    chattr +ai ${i}
    if [[ $? == 0 ]];then
        echo "安全: 已成功锁定关键系统文件${i}"
    else
        echo "警告: 未成功锁定关键系统文件${i}"
    fi
done
# CPU使用检查
allcpu_idle_rate=''
check=`top -n 1 | awk -F ',' 'NR==3 {print $4}'|awk '{print $1}'|awk -F '.' '{print $1}'|grep '^[0-9]'`
if [[ ${check} != '' ]];then
    allcpu_idle_rate=`top -n 1 | awk -F ',' 'NR==3 {print $4}'|awk '{print $1}'|awk -F '.' '{print $1}'`
else
    allcpu_idle_rate=`top -n 1 | awk -F ',' 'NR==3 {print $4}'|awk '{print $2}'| awk -F '.' '{print $1}'`
fi
allcpu_used_rate=$((100 - ${allcpu_idle_rate}))
if [[ ${allcpu_used_rate} -ge 80 ]];then
    echo "警告: 当前CPU总的使用率为${allcpu_used_rate}%(大于80%),请优化不必要的使用"
else
    echo "安全: 当前CPU总的使用率为${allcpu_used_rate}%(小于80%),符合使用要求"
fi
# 内存使用检查
memory_used=`free -m | grep 'Mem:'|awk '{print $3}'`
memory_all=`free -m | grep 'Mem:'|awk '{print $2}'`
memory_space_rate=`awk 'BEGIN{printf"%.2f%\n",('145'/'7822')*100}'|awk -F '%' '+$1 > 80 {print $1}'`
if [[ ${memory_space_rate} != '' ]];then
    echo "警告: 当前内存的使用率为${memory_space_rate}(大于80%),请扩充其容量或优化不必要的内存使用"
else
    echo "安全: 当前内存的使用率小于80%,符合安全要求"
fi
# 磁盘使用检查
disk_space=`df -h | grep -v 'tmpfs' | grep '/dev/' | awk '+$5 > 80 {print $5}'`
if [[ ${disk_space} != '' ]];then
    for i in ${disk_space};do
        echo "警告: 当前某磁盘的使用率为${i}(大于80%),请扩充其容量或删除不必要的文件"
    done
else
    echo "安全: 当前各磁盘的使用率均小于80%,符合安全要求"
fi
# 9---rootkit等病毒、木马和后门程序安全检查
yum -y install rkhunter > /dev/null
if [[ $? == 0 ]];then
    echo "消息: 安全检查工具rkhunter安装成功,请使用命令\"rkhunter -c\"检查系统安全"
else
    echo "警告: 安全检查工具rkhunter未成功安装"
fi
