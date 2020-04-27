#!/bin/bash
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin;
export PATH
function traffic_monitor {
  # 系统版本
  OS_NAME=$(sed -n '1p' /etc/issue)
  # 网口名
  eth=$1
  #判断网卡存在与否,不存在则退出
  if [ ! -d /sys/class/net/$eth ];then
      echo -e "Network-Interface Not Found"
      echo -e "You system have network-interface:\n`ls /sys/class/net`"
      exit 5
  fi
  while [ "1" ]
  do
    # 状态
    STATUS="fine"
    # 获取当前时刻网口接收与发送的流量
    RXpre=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $2}')
    TXpre=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $10}')
    # 获取1秒后网口接收与发送的流量
    sleep 1
    RXnext=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $2}')
    TXnext=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $10}')
    clear
    # 获取这1秒钟实际的进出流量
    RX=$((${RXnext}-${RXpre}))
    TX=$((${TXnext}-${TXpre}))
    # 判断接收流量如果大于MB数量级则显示MB单位,否则显示KB数量级
    if [[ $RX -lt 1024 ]];then
      RX="${RX}B/s"
    elif [[ $RX -gt 1048576 ]];then
      RX=$(echo $RX | awk '{print $1/1048576 "MB/s"}')
      $STATUS="busy"
    else
      RX=$(echo $RX | awk '{print $1/1024 "KB/s"}')
    fi
    # 判断发送流量如果大于MB数量级则显示MB单位,否则显示KB数量级
    if [[ $TX -lt 1024 ]];then
      TX="${TX}B/s"
      elif [[ $TX -gt 1048576 ]];then
      TX=$(echo $TX | awk '{print $1/1048576 "MB/s"}')
    else
      TX=$(echo $TX | awk '{print $1/1024 "KB/s"}')
    fi
    # 打印信息
    echo -e "==================================="
    echo -e "Welcome to Traffic_Monitor stage"
    echo -e "version 1.0"
    echo -e "Since 2014.2.26"
    echo -e "Created by showerlee"
    echo -e "==================================="
    echo -e "System: $OS_NAME"
    echo -e "Date:   `date +%F`"
    echo -e "Time:   `date +%k:%M:%S`"
    echo -e "Port:   $1"
    echo -e "Status: $STATUS"
    echo -e  " \t     RX \tTX"
    echo "------------------------------"
    # 打印实时流量
    echo -e "$eth \t $RX   $TX "
    echo "------------------------------"
    # 退出信息
    echo -e "Press 'Ctrl+C' to exit"
  done
}
# 判断执行参数
if [[ -n "$1" ]];then
  # 执行函数
  traffic_monitor $1
else
  echo -e "None parameter,please add system netport after run the script! \nExample: 'sh traffic_monitor eth0'"
fi
