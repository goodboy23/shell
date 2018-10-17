#!/bin/bash
# 作者：日行一善 <qq：1969679546> <email：1969679546@qq.com>
# 官网：www.52wiki.cn
#
# 日期：2018/4/12
# 介绍：mysql_info.sh 信息查看脚本
#
# 注意：适用于5.7版本，其它版本要更改变量hang为2
# 功能：查看mysql的信息，用于比对和查询条目数
#
# 适用：centos6+
# 语言：中文



#all/库名，取最后一个传进来的参数
sql_sql=""

#从哪行取参数，因为5.7版本有警告信息，所以从第三行取。
hang=3

#对参数进行区分
for i in `echo $@`
do
    echo ${i} | grep '-' &> /dev/null #如果是带-的参数做处理
    if [[ $? -eq 0 ]];then
        echo ${i} | grep ^-u &> /dev/null
        [[ $? -eq 0 ]] && usr=`echo $i | awk -F'-u' '{print $2}'`
        echo ${i} | grep ^-p &> /dev/null
        [[ $? -eq 0 ]] && pas=`echo $i | awk -F'-p' '{print $2}'`
        echo ${i} | grep ^-h &> /dev/null
        [[ $? -eq 0 ]] && hos=`echo $i | awk -F'-h' '{print $2}'`
        echo ${i} | grep ^-P &> /dev/null
        [[ $? -eq 0 ]] && por=`echo $i | awk -F'-P' '{print $2}'`
        echo ${i} | grep ^--so &> /dev/null
        [[ $? -eq 0 ]] && soc=`echo $i | awk -F'--socket=' '{print $2}'`
    else
        sql_sql="$i" #剩下的最后做判断
    fi
done

#对传入的参数进行组合，组合成登录命令
if [[ $usr ]] && [[ $pas ]] && [[ $hos ]] && [[ $por ]] && [[ $soc ]];then
    my_sql="mysql -u${usr} -p${pas} -h${hos} -P${por} --socket=${soc}"
elif [[ $usr ]] && [[ $pas ]] && [[ $hos ]] && [[ $por ]];then
    my_sql="mysql -u${usr} -p${pas} -h${hos} -P${por}"
elif [[ $usr ]] && [[ $pas ]] && [[ $hos ]];then
    my_sql="mysql -u${usr} -p${pas} -h${hos}"
elif [[ $usr ]] && [[ $pas ]];then
    my_sql="mysql -u${usr} -p${pas}"
else
    echo "至少有-u -p参数"
    exit 1
fi

#检查登录命令是否正确
${my_sql} -e "show databases;" &> /tmp/info_error.txt
if [[ $? -ne 0 ]];then
    echo "登录命令错误"
    cat /tmp/info_error.txt #如果错误则显示错误信息
    exit
fi

#数据库的名字获取
${my_sql} -e "show databases;" &> /tmp/ku_name.txt
ku_name=(`tail -n +${hang} /tmp/ku_name.txt`)
ku_number=${#ku_name[*]}
let ku_number--

#数据库信息获取并显示
ku_info() {
    for i in `seq 0 ${ku_number}`
    do
        echo ${ku_name[i]}
    done
}

#表信息
biao_info() {
    ${my_sql} -e "use $1 ; show tables;" &> /tmp/biao_name.txt
    biao_name=(`tail -n +${hang} /tmp/biao_name.txt`)
    biao_number=${#biao_name[*]}
    let biao_number--
    biao_shu=()
    biao_zong=0

    for i in `seq 0 ${biao_number}`
    do
        ${my_sql} -e "use ${1} ; SELECT count(*) FROM ${biao_name[i]};" &> /tmp/biao_shu.txt
        shu=(`tail -n +${hang} /tmp/biao_shu.txt`)
        biao_shu[i]=$shu
    done

    echo "${1}数据库信息如下:"
    for i in `seq 0 ${biao_number}`
    do
        echo "表名:${biao_name[i]} 条目数:${biao_shu[i]}"
        let biao_zong+=biao_shu[i]
    done
    echo
    echo "总条目数：${biao_zong}"
} 

echo "./mysql_info.sh + 登录参数 + all/库名
all查询当前拥有的库，库名显示数据库每个表的条目数和总条目数

例子:
./mysql_info.sh -uroot -p'test' -h1.1.1.1 --socket=/test/mysql.sock all
./mysql_info.sh -uroot -p'test' -h1.1.1.1 all
./mysql_info.sh -uroot -p'test' all


"



if [[ $sql_sql == "all" ]];then
    echo "当前拥有的库"
    ku_info
else
    echo "${ku_name[*]}" | grep -w $sql_sql &> /dev/null
    if [[ $? -ne 0 ]];then
            echo "填写的库不存在"
            exit
     fi
        biao_info ${sql_sql}
fi
