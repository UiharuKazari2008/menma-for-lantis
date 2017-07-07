#!/bin/bash
if [ $# -lt 1 ]; then echo "No Input Data"; exit 1; fi
# LANTIS + Menma 2 #
# OPERATIONS ###########################################################################################################
TEST_HOST_VERIFY () { 
${CMD_SSH} ${SIDE_A_HOST} -l ${SIDE_A_USER} -p ${SIDE_A_PORT} -i ${KEY} ${COMMON_OPT} << EOF
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Side A: OK"
EOF
${CMD_SSH} ${SIDE_B_HOST} -l ${SIDE_B_USER} -p ${SIDE_B_PORT} -i ${KEY} ${COMMON_OPT} << EOF
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Side B: OK"
EOF
}
TEST_HOST_FAILED () { 
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!] Server Verification: No Access"
HOST_FAILED=1
}
TEST_INET_VERIFY () {
wget -q --spider ${HOST_VERIFY} --timeout=${TIMEOUT_VERIFY_INET}
}
TEST_INET_PASSED () {
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Internet Connection: OK"
}
TEST_INET_FAILED () {
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!] Internet Connection: Failed"; 
sleep ${TIME_FAILED_INET}
}
TEST_CONN_FAILED () {
echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][ERR!] Sync failed!"
sleep ${TIME_FAILED_CONN}
}
TRANSFER () {
if [ ${DRY} = 1 ]; then echo "${CMD_SCP} ${COMMON_OPT} -p -r -P ${SIDE_A_PORT} $(if [ ${DIRECTION} = ">" ]; then echo "${SIDEA} ${SIDEB}"; elif [ ${DIRECTION} = "<" ]; then echo "${SIDEB} ${SIDEA}"; fi)"
else ${CMD_SCP} ${COMMON_OPT} -p -r -P ${SIDE_A_PORT} $(if [ ${DIRECTION} = ">" ]; then echo "${SIDEA} ${SIDEB}"; elif [ ${DIRECTION} = "<" ]; then echo "${SIDEB} ${SIDEA}"; fi); fi
}
RUN() {
while read in; do
if [[ $(echo $in | awk -F '[ ]' '{print $1}') != "#" ]]; then
	if [[ $(echo $in | awk -F '[;]' '{print $1}') = "e" ]]; then
		# e;test;127.4.4.2,22,root;43.543.45.44;22;root;/root;<;/root/backup;X;X;
		HOST_FAILED=0
		CONNECTION_STATUS=$(echo $in | awk -F '[;]' '{print $1}')  #Enabled[E or D]
		CONNECTION_NAME=$(echo $in | awk -F '[;]' '{print $2}')    #Name[string]
		L_SIDE_A_HOST=$(echo $in | awk -F '[;]' '{print $3}')      #Side A Host[string]
		L_SIDE_A_PORT=$(echo $in | awk -F '[;]' '{print $4}')      #Side A Port[string]
		L_SIDE_A_USER=$(echo $in | awk -F '[;]' '{print $5}')      #Side A User[string]
		L_SIDE_B_HOST=$(echo $in | awk -F '[;]' '{print $6}')      #Side B Host[string]
		L_SIDE_B_PORT=$(echo $in | awk -F '[;]' '{print $7}')      #Side B Port[string]
		L_SIDE_B_USER=$(echo $in | awk -F '[;]' '{print $8}')      #Side B User[string]
		L_SIDE_A_FILES=$(echo $in | awk -F '[;]' '{print $9}')     #Remote Files and Folders[string]
		L_SIDE_B_FILES=$(echo $in | awk -F '[;]' '{print $11}')    #Local Files and Folders[string]
		L_DIRECTION=$(echo $in | awk -F '[;]' '{print $10}')       #Direction[string]
		L_SIDE_A_SCRIPT=$(echo $in | awk -F '[;]' '{print $12}')   #Remote Post script[string]
		L_SIDE_B_SCRIPT=$(echo $in | awk -F '[;]' '{print $13}')   #Local Post script[string]
		
		if [ ${L_SIDE_A_HOST}   != "^" ]; then SIDE_A_HOST=${L_SIDE_A_HOST};     fi
		if [ ${L_SIDE_A_PORT}   != "^" ]; then SIDE_A_PORT=${L_SIDE_A_PORT};     fi
		if [ ${L_SIDE_A_USER}   != "^" ]; then SIDE_A_USER=${L_SIDE_A_USER};     fi
		if [ ${L_SIDE_B_HOST}   != "^" ]; then SIDE_B_HOST=${L_SIDE_B_HOST};     fi
		if [ ${L_SIDE_B_PORT}   != "^" ]; then SIDE_B_PORT=${L_SIDE_B_PORT};     fi
		if [ ${L_SIDE_B_USER}   != "^" ]; then SIDE_B_USER=${L_SIDE_B_USER};     fi
		if [ ${L_SIDE_A_FILES}  != "^" ]; then SIDE_A_FILES=${L_SIDE_A_FILES};   fi
		if [ ${L_DIRECTION}     != "^" ]; then DIRECTION=${L_DIRECTION};         fi
		if [ ${L_SIDE_B_FILES}  != "^" ]; then SIDE_B_FILES=${L_SIDE_B_FILES};   fi
		if [ ${L_SIDE_A_SCRIPT} != "^" ]; then SIDE_A_SCRIPT=${L_SIDE_A_SCRIPT}; fi
		if [ ${L_SIDE_B_SCRIPT} != "^" ]; then SIDE_B_SCRIPT=${L_SIDE_B_SCRIPT}; fi
		
		if TEST_INET_VERIFY; then TEST_INET_PASSED
			#{ TEST_HOST_VERIFY 
			#} || { TEST_HOST_FAILED 
			#}; 
			HOST_FAILED=0
			if [ ${HOST_FAILED} -eq 0 ]; then
				SIDEA="$(if [ $SIDE_A_HOST = "X" ]; then echo "${SIDE_A_FILES}"; else echo "${SIDE_A_USER}@${SIDE_A_HOST}:${SIDE_A_FILES}"; fi)"
				SIDEB="$(if [ $SIDE_B_HOST = "X" ]; then echo "${SIDE_B_FILES}"; else echo "${SIDE_B_USER}@${SIDE_B_HOST}:${SIDE_B_FILES}"; fi)"
				{   TRANSFER
					echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][INFO] Transfer OK"
				} || { echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][FAIL] Transfer Failed!"
				}
			elif [ ${HOST_FAILED} -eq 1 ]; then
				echo "[${CONNECTION_NAME}][$(date "${DATE_FORMAT}")][FAIL] Host Failed!"
			fi
		else TEST_INET_FAILED
		fi
	fi
fi
done < $BACKUP_LIST
}

DRY=0; BACKUP_LIST="./sync.lantis.csv"; LOG_FILE="./lantis.log"; TIME_LAUNCH_PAUSE=4; TIME_DROP_PAUSE=2; DATE_FORMAT='+%d/%m/%Y %H:%M:%S'
TIME_FAILED_CONN=2; TIME_FAILED_INET=5; TIMEOUT_VERIFY_INET=15; HOST_VERIFY="https://google.com"; CMD_SSH="ssh"; CMD_SCP="scp"
HOST_FAILED=0; EMAIL=0; KEY=lantis.key
COMMON_OPT="-C -o CompressionLevel=9 -2 -o BatchMode=yes -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=5 -o ConnectTimeout=15 -o LogLevel=Error"
source ./.lantis.config
# MAIN RUNTIME #########################################################################################################
echo "= Menma Sync 2 - Academy City Research ========="
echo "[---------][$(date "${DATE_FORMAT}")][ OK ] System Ready"
# PARSE INPUT ##########################################################################################################
while getopts "C:XeRr:" opt; do 
  case $opt in
  	C) PORT_LIST="${OPTARG}";;
	X) DRY=1;;
	e) EMAIL=1;;
	R) HEADER; RUN 1;;
	r) RUN ${OPTARG};;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done