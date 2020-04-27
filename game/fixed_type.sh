#!/bin/bash

a=3
b=20 #zifu

p_exit() {
echo -e "\033[?25h"    #显示光标
stty echo    #显示输出内容
clear
exit
}

echo -e "\033[?25l" #关闭光标
stty -echo

trap "p_exit;" INT TERM    #当强制退出则执行p_exit函数内容

while [ 1 ]
do
    read -n 1 key
    if [[ "[$key]" == "[]" ]];then
        let a+=3
        b=20
    else
        echo -e "\033["41"m\033[${a};${b}H${key}\033[0m"
        let b++
    fi
done
