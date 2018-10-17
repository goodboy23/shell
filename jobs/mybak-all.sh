#!/bin/bash
# 作者：日行一善 <qq：1969679546> <email：1969679546@qq.com>
# 官网：www.52wiki.cn
#
# 日期：2018/10/8
# 介绍：mybak-all.sh mysqldump方式全备份脚本
#
# 注意：使用前先测试，并修改对应的变量。
# 功能：全备份脚本
#
# 适用：centos6+
# 语言：中文
#
#使用：./xx.sh -uroot -p'123456'，使用前进行变量配置
#过程：备份并刷新binlog，将最新的binlog文件名记录并整体压缩打包
#恢复：先进行全量备份，再对根据tim-binlog.txt中的记录，进行逐个恢复。



#[变量]
#mysql这个命令所在位置，绝对路径
my_sql="/usr/local/mysql/bin/mysql"

#mysqldump这个命令所在位置，绝对路径
bak_sql="/usr/local/mysql/bin/mysqldump"

#binlog日志所在目录
binlog_dir=/usr/local/mysql/data

#要备份到哪个目录
bak_dir=/ops/bak

#这个脚本的日志输出到哪个文件
log_dir=/ops/log/mybak-all.log

#保存的天数，4周就是28天
save_day=3


begin_time=`date +%F-%H-%M-%S`

#[自动变量]
#当前年月
date_nian=`date +%Y-`

#所有天数的数组
save_day_zu=($(for i in `seq 1 ${save_day}`;do date -d -${i}days "+%F";done))


#开始
/usr/bin/echo >> ${log_dir}
/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:开始全备份" >> ${log_dir}


#检查
${my_sql} $* -e "show databases;" &> /tmp/info_error.txt
if [[ $? -ne 0 ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:登陆命令错误" >> ${log_dir}
	/usr/bin/cat /tmp/info_error.txt #如果错误则显示错误信息
	exit 1
fi

#移动到目录
cd ${bak_dir}
bak_time=`date +%F-%H-%M`
bak_timetwo=`date +%F`

#备份
${bak_sql} $* --all-databases --flush-privileges --single-transaction --flush-logs --triggers --routines --events --hex-blob > mybak-all-${bak_time}.sql
if [[ $? -ne 0 ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) error:备份失败"
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) error:备份失败" >> ${log_dir}
	/usr/bin/cat /tmp/bak_error.txt #如果错误则显示错误信息
	exit 1
else
	bin_dian=`tail -n 1 ${binlog_dir}/mysql-bin.index`
	echo "${bin_dian}" > ${bak_time}-binlog.txt
fi

#压缩
if [[ -f mybak-all-${bak_time}.tar.gz ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:压缩包mybak-section-${bak_time}.tar.gz 已存在" >> ${log_dir}
	/usr/bin/rm -irf mybak-all-${bak_time}.tar.gz ${bak_sql}-binlog.txt
fi

/usr/bin/tar -cf mybak-all-${bak_time}.tar.gz mybak-all-${bak_time}.sql ${bak_time}-binlog.txt
if [[ $? -ne 0 ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) error:压缩失败" >> ${log_dir}
	exit 1
fi

#删除sql文件
/usr/bin/rm -irf mybak-all-${bak_time}.sql ${bak_time}-binlog.txt
if [[ $? -ne 0 ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:删除sql文件失败" >> ${log_dir}
	exit 1
fi

#整理压缩的日志文件
for i in `ls | grep .tar.gz$`
   do
    echo $i | grep "^mybak-all.*tar.gz$" &> /dev/null
        if [[ $? -eq 0 ]];then
            a=`echo ${i%%.tar.gz}`
            b=`echo ${a:(-16)}`
			c=`echo ${b%-*}`
			d=`echo ${c%-*}`
        
            #看是否在数组中，不在则删除
            echo ${save_day_zu[*]} |grep -w $d &> /dev/null
            if [[ $? -ne 0 ]];then
                [[ "$d" != "$bak_timetwo" ]] && rm -rf $i
            fi
        else
            #不是当月的，其他类型压缩包，跳过
            continue
        fi
done



#结束
last_time=`date +%F-%H-%M-%S`
/usr/bin/echo "begin_time:${begin_time}   last_time:${last_time}" >> ${log_dir}
/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:全备份完成" >> ${log_dir}
/usr/bin/echo >> ${log_dir}
