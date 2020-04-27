#!/bin/bash

#数组
qiu=(0 1 2 3 4 5 6 7 8 9 )



#数组总长度
qiu_chang=${#qiu[*]}
let qiu_chang--

#重新计算数组，将原数组剔除，然后重新挨个加到原数组
shuzu(){
	local a=0
	unset qiu[$shu]
	for i in `echo ${qiu[*]}`
	do
		qiu[$a]=$i
		let a++
	done
}

if [ $# -ne 1 ];then
	echo "./xx.sh 5 来随机出5次"
	echo "当前数组：${qiu[*]}"
	exit
fi

#不能超过数组长度
if [ $1 -ge ${qiu_chang} ];then
	echo "不能超过数组长度"
	exit
fi

#根据下标来删除数组中的元素
for i in `seq 0 $1`
do
	shu=`echo $[RANDOM%qiu_chang]`
	#输出一下
	echo ${qiu[$shu]}
	shuzu
	let qiu_chang--
done
