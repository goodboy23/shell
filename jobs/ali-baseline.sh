#!/bin/bash


cy() {
    #检查密码重用是否受限制

    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep 'password' $1 |grep sufficient |grep remember &> /dev/null
    if [[ $? -eq 0 ]];then
        echo "[cy] already exists"
    else
    	grep 'use_authtok' $1 &> /dev/null
    	if [[ $? -eq 0 ]];then #这行存在则末尾加字符
    		sed -i 's/use_authtok$/& remember=5/' $1
    	else
    		echo "[cy] No such line"
    		exit 1
        fi
    fi
}

li() {
    #确保SSH LogLevel设置为INFO

    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep '^LogLevel INFO' $1 &> /dev/null
    if [[ $? -eq 0 ]];then
         echo "[li] already exists"
    else #先删除已经存在参数，再追加
        sed -i "/^LogLevel/ d" $1
        echo 'LogLevel INFO' >> $1
    fi
}

kx() {
    #设置SSH空闲超时退出时间
    
    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep '^ClientAliveInterval 300' $1 &> /dev/null
    a=$?
    grep '^ClientAliveCountMax 2' $1 &> /dev/null
    b=$?

    if [[ $a -eq 0 ]] && [[ $b -eq 0 ]];then
        echo "[kx] already exists"
    else
        sed -i "/^ClientAliveInterval/ d" $1
        sed -i "/^ClientAliveCountMax/ d" $1
        echo "ClientAliveInterval 300" >> $1
        echo "ClientAliveCountMax 2" >> $1
    fi
}

aq() {
    #SSHD强制使用V2安全协议
    
    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep '^Protocol 2' $1 &> /dev/null
    if [[ $? -eq 0 ]];then
        echo "[aq] already exists"
    else
        sed -i "/^Protocol/ d" $1
        echo 'Protocol 2' >> $1
    fi
}

ma() {
    #确保SSH MaxAuthTries设置为3到6之间

    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep '^MaxAuthTries 4' $1 &> /dev/null
    if [[ $? -eq 0 ]];then
        echo "[ma] already exists"
    else
        sed -i "/^MaxAuthTries/ d" $1
        echo 'MaxAuthTries 4' >> $1
    fi
}

jg() {
    #设置密码修改最小间隔时间

    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep '^PASS_MIN_DAYS   7' $1 &> /dev/null
    if [[ $? -eq 0 ]];then
        echo "[jg] already exists"
    else
        sed -i "/^PASS_MIN_DAYS/ d" $1
        echo 'PASS_MIN_DAYS   7' >> $1
        chage --mindays 7 root
    fi
}

sx() {
    #设置密码失效时间

    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep '^PASS_MAX_DAYS   90' $1 &> /dev/null
    if [[ $? -eq 0 ]];then
        echo "[sx] already exists"
    else
        sed -i "/^PASS_MAX_DAYS/ d" $1
        echo 'PASS_MAX_DAYS   90' >> $1
        chage --maxdays 90 root
    fi
}

fz() {
    #密码复杂度检查

    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep '^minlen=10' $1 &> /dev/null
    a=$?
    grep '^minclass=3' $1 &> /dev/null
    b=$?

    if [[ $a -eq 0 ]] && [[ $b -eq 0 ]];then
        echo "[fz] already exists"
    else
        sed -i "/^minlen/ d" $1
        sed -i "/^minclass/ d" $1
        echo "minlen=10" >> $1
        echo "minclass=3" >> $1
    fi
}

fz_liu() {
    #密码复杂度检查-6版本

    if [[ ! -f $1 ]];then
        echo "$1 not found"
        exit 1
    fi

    grep 'password' $1 |grep requisite |grep minclass=3  $1 &> /dev/null
    if [[ $? -eq 0 ]];then
        echo "[fz_liu] already exists"
    else
        grep 'pam_cracklib.so' $1 &> /dev/null
        if [[ $? -eq 0 ]];then #这行存在则末尾加字符
            sed -i 's/type=$/& minlen=11 minclass=3/' $1
        else
            echo "[fz_liu] No such line"
            exit 1
        fi
    fi
}

grep ' 7.' /etc/redhat-release &>/dev/null
if [[ $? -eq 0 ]];then
    #检查密码重用是否受限制
    cy /etc/pam.d/password-auth
    cy /etc/pam.d/system-auth

    #确保SSH LogLevel设置为INFO
    li /etc/ssh/sshd_config

    #设置SSH空闲超时退出时间
    kx /etc/ssh/sshd_config

    #SSHD强制使用V2安全协议
    aq /etc/ssh/sshd_config

    #确保SSH MaxAuthTries设置为3到6之间
    ma /etc/ssh/sshd_config

    #设置密码修改最小间隔时间
    jg /etc/login.defs

    #设置密码失效时间
    sx /etc/login.defs

    #密码复杂度检查
    fz /etc/security/pwquality.conf

    exit
fi

grep ' 6.' /etc/redhat-release &>/dev/null
if [[ $? -eq 0 ]];then
    #检查密码重用是否受限制
    cy /etc/pam.d/password-auth
    cy /etc/pam.d/system-auth

    #设置SSH空闲超时退出时间
    kx /etc/ssh/sshd_config

    #确保SSH MaxAuthTries设置为3到6之间
    ma /etc/ssh/sshd_config

    #设置密码修改最小间隔时间
    jg /etc/login.defs

    #设置密码失效时间
    sx /etc/login.defs

    #密码复杂度-六
    fz_liu /etc/pam.d/password-auth
    fz_liu /etc/pam.d/system-auth

    #确保SSH LogLevel设置为INFO
    li /etc/ssh/sshd_config

    exit
else
    echo  "System does not support"
fi
