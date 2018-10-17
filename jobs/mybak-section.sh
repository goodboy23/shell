#!/bin/bash
# 作者：日行一善 <qq：1969679546> <email：1969679546@qq.com>
# 官网：www.52wiki.cn
#
# 日期：2018/4/12
# 介绍：mybak-section.sh 复制Binlog日志方式的增量备份脚本
#
# 注意：执行脚本前修改脚本中的变量
# 功能：cp方式增量备份
#
# 适用：centos6+
# 语言：中文
#
#使用：./xx.sh -uroot -p'123456'，将第一次增量备份后的binlog文件名写到/tmp/binlog-section中，若都没有，填写mysql-bin.000001
#过程：增量先刷新binlog日志，再查询/tmp/binlog-section中记录的上一次备份中最新的binlog日志的值
#      cp中间的binlog日志，并进行压缩。再将备份中最新的binlog日志写入。
#恢复：先进行全量恢复，再根据全量备份附带的time-binlog.txt中的记录逐个恢复。当前最新的Binlog日志要去掉有问题的语句，例如drop等。



#[变量]
#mysql这个命令所在绝对路径
my_sql="/usr/local/mysql/bin/mysql"

#mysqldump命令所在绝对路径
bak_sql="/usr/local/mysql/bin/mysqldump"

#binlog日志所在目录
binlog_dir=/usr/local/mysql/data

#mysql-bin.index文件所在位置
binlog_index=${binlog_dir}/mysql-bin.index

#备份到哪个目录
bak_dir=/ops/bak

#这个脚本的日志输出到哪个文件
log_dir=/ops/log/mybak-section.log

#保存的天数，4周就是28天
save_day=3

#[自动变量]
#当前年
date_nian=`date +%Y-`

begin_time=`date +%F-%H-%M-%S`



#所有天数的数组
save_day_zu=($(for i in `seq 1 ${save_day}`;do date -d -${i}days "+%F";done))



#开始
/usr/bin/echo >> ${log_dir}
/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:开始增量备份" >> ${log_dir}


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

#刷新
${my_sql} $* -e "flush logs"
if [[ $? -ne 0 ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) error:刷新binlog失败" >> ${log_dir}
	exit 1
fi

#获取开头和结尾binlog名字
last_bin=`cat /tmp/binlog-section`
next_bin=`tail -n 1 ${binlog_dir}/mysql-bin.index`
echo ${last_bin} |grep 'mysql-bin' &> /dev/null
if [[ $? -ne 0 ]];then
	echo "mysql-bin.000001" > /tmp/binlog-section #不存在则默认第一个
	last_bin=`cat /tmp/binlog-section`
fi

#截取需要备份的binlog行数
a=`/usr/bin/sort ${binlog_dir}/mysql-bin.index | uniq | grep -n ${last_bin} | awk -F':' '{print $1}'`
b=`/usr/bin/sort ${binlog_dir}/mysql-bin.index | uniq | grep -n ${next_bin} | awk -F':' '{print $1}'`

let b--

#输出最新节点
/usr/bin/echo "${next_bin}" > /tmp/binlog-section

#创建文件
rm -rf mybak-section-${bak_time}
/usr/bin/mkdir mybak-section-${bak_time}

for i in `sed -n "${a},${b}p" ${binlog_dir}/mysql-bin.index  | awk -F'./' '{print $2}'`
do
	if [[ ! -f ${binlog_dir}/${i} ]];then
		/usr/bin/echo "time:$(date +%F-%H-%M-%S) error:binlog文件${i} 不存在" >> ${log_dir}
		exit 1
	fi
	
	cp -rf ${binlog_dir}/${i} mybak-section-${bak_time}/
	if [[ ! -f mybak-section-${bak_time}/${i} ]];then
		/usr/bin/echo "time:$(date +%F-%H-%M-%S) error:binlog文件${i} 备份失败" >> ${log_dir}
		exit 1
	fi
done

#压缩
if [[ -f mybak-section-${bak_time}.tar.gz ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:压缩包mybak-section-${bak_time}.tar.gz 已存在" >> ${log_dir}
	/usr/bin/rm -irf mybak-section-${bak_time}.tar.gz
fi

/usr/bin/tar -cf mybak-section-${bak_time}.tar.gz mybak-section-${bak_time}
if [[ $? -ne 0 ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) error:压缩失败" >> ${log_dir}
	exit 1
fi

#删除binlog文件夹
/usr/bin/rm -irf mybak-section-${bak_time}
if [[ $? -ne 0 ]];then
	/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:删除sql文件失败" >> ${log_dir}
	exit 1
fi

#整理压缩的日志文件
for i in `ls | grep "^mybak-section.*tar.gz$"`
   do
    echo $i | grep ${date_nian} &> /dev/null
        if [[ $? -eq 0 ]];then
            a=`echo ${i%%.tar.gz}`
            b=`echo ${a:(-16)}` #当前日志年月日
			c=`echo ${b%-*}`
			d=`echo ${c%-*}`
        
            #看是否在数组中，不在其中，并且不是当前时间，则删除。
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
/usr/bin/echo "time:$(date +%F-%H-%M-%S) info:增量备份完成" >> ${log_dir}
/usr/bin/echo >> ${log_dir}
