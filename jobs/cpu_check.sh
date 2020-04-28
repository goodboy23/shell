#!/bin/bash
# 作者：奚博伟
# 邮箱：516601965@qq.com
# 日期：2018年8月24日
# 功能：查看主板上单个多核CPU中温度最高的一个内核
# 脚本依赖：lm_sensors工具，可以执行下面语句进行安装，如果安装不了请更换YUM源
# 工具安装命令：yum install -y lm_sensors
# 注意事项：
# 1.“sensors  coretemp-isa-0000”中后面的参数视主机实际的参数而定
# 2.目前vmware虚拟机中lm_sensors工具无法查看硬件温度 

CPU0=`sensors  coretemp-isa-0000 | tail -n +3 |tr -s " " |awk -F [°C+] '{print $1$3}'`
CPU1=`sensors  coretemp-isa-0004 | tail -n +3 |tr -s " " |awk -F [°C+] '{print $1$3}'`

function cpu0 {
	max0=0.0
        for i in $CPU0;do
                if [ ${i%.*} -gt ${max0%.*} ];then
			max0=$i
                fi
        done
	echo $max0
}


function cpu1 {
	max1=0.0
        for j in $CPU1;do
                if [ ${j%.*} -gt ${max1%.*} ];then
			max1=$j
                fi
        done
	echo $max1
}

$1
