#!/bin/bash

screen_start() {
	if [[ $scpid ]];then
		echo "Error: $1 Already running"
		exit 0
	else	
		#创建终端
		screen -dmS $1
		screen -x -S ca -p 0 -X stuff "./${1}.sh"
		screen -x -S ca -p 0 -X stuff '\n'
	fi
}

screen_stop() {
	if [[ $scpid ]];then
		kill $scpid
		scpid=`ps -aux | grep "[S]CREEN -dmS $1" | awk '{print $2}'`
		[[ "$scpid" ]] && echo "Error: Screen close failed pid=${scpid}"
	else
		echo "Error: Can't get screen $1 pid number"
		exit 1
	fi
}

screen_status() {
	if [[ $scpid ]];then
		 echo "screen $1 running"
	else
		 echo "screen $1 shut down"
	fi
}



#主体
if [[ ! "$2" ]];then
	echo "please ${0} start|stop|restart|status client80"
	exit 2
fi

#是否存在这个程序
if [[ ! -f ${2}.sh ]];then
	echo "Error: ${2}.sh file not found"
	exit 1
fi	

#pid号
scpid=`ps -aux | grep "[S]CREEN -dmS $2" | awk '{print $2}'`

if [[ "$1" == "start" ]];then
	screen_start $2
elif [[ "$1" == "stop" ]];then
	screen_stop $2
elif [[ "$1" == "restart" ]];then
	screen_stop $2
	screen_start $2
elif [[ "$1" == "status" ]];then
	screen_status $2
else
	echo "please ${0} start|stop|restart|status client80"
fi	
