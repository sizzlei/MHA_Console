#!/bin/sh
clear
mha_base=/mha
mha_conf=${mha_base}/
mha_work=${mha_base}/
check_msg=''


while true; do 
echo '############################################'
echo '#   MHADM(MHA Administrator) Console v1.0  #'
echo '#   Create by Sizzlei                      #'
echo '#   Date : 2018-12-19                      #'
echo '############################################'
echo ''
echo ${check_msg}
echo ''
echo '## Job List ##'
echo '1) SSH Check'
echo '2) Replication Check'
echo '3) MHA VIP(Virtual IP) Check'
echo '4) MHA Manager Start'
echo '5) MHA Manager Stop'
echo '6) MHA Master Switching'
echo '7) MHADM Exit'
echo -n 'Select Job Number : '
read job_num
clear

case ${job_num} in
	1)
		masterha_check_ssh --conf=${mha_conf} > ${mha_base}/.ssh_check.log 2>&1
		ssh_check_str=$(cat ${mha_base}/.ssh_check.log|grep 'All SSH connection tests passed successfully.'|awk '{print $8,$9,$10,$11,$12,$13}')
		if [[ $ssh_check_str == "All SSH connection tests passed successfully." ]]; then
			check_msg='	MHA SSH CHECK : Success'
		else 
			check_msg='	MHA SSH CHECK : Fail'
		fi
		rm -rf ${mha_base}/.ssh_check.log
	;;
	2)
		masterha_check_repl --conf=${mha_conf} > ${mha_base}/.repl_check.log 2>&1
		repl_check_str=$(cat ${mha_base}/.repl_check.log|grep 'MySQL Replication Health is OK.'|awk '{print $1,$2,$3,$4,$5}')
		if [[ $repl_check_str == "MySQL Replication Health is OK." ]]; then
			check_msg='	MySQL Replication CHECK : Success'
		else 
			check_msg='	MySQL Replicatoin CHECK : Fail'
		fi
		rm -rf ${mha_base}/.repl_check.log
	;;
	3)
		mha_vip=$(cat ${mha_base}/scripts/mha_failover|grep 'my $ssh_mac_refresh'|awk '{print $11}')
		ping_str=$(ping ${mha_vip} -c1 |grep 'received'|awk '{print $4}')
		if [[ $ping_str -eq "1" ]]; then
			check_msg_st=' : OK'
		else
			check_msg_st=' : Fail'
		fi
		check_msg=${mha_vip}${check_msg_st}
	;;
	4)
		rm -rf ${mha_work}/mha.failover.complete
		masterha_check_status --conf=${mha_conf} > ${mha_base}/.status_check.log 2>&1
		start_check=$(cat ${mha_base}/.status_check.log|awk '{print $4}')
		if [[ $start_check == "running(0:PING_OK)," ]]; then
			check_msg='MHA is Now Running'
		else
			echo -n 'Do you accept to MHA Execution?(Y/N) : '
			read run_apply
			case ${run_apply} in
				Y|y)
					nohup masterha_manager --conf=${mha_conf} 1> /dev/null 2>&1 &
					for ((a=0;a<10;a++)); do
						echo -n '='
						sleep 1
					done
					check_msg=$(masterha_check_status --conf=${mha_conf})
				;;
				N|n)
					break
				;;
			esac
		fi
		rm -rf ${mha_base}/.status_check.log
	;;
	5)
		masterha_check_status --conf=${mha_conf} > ${mha_base}/.status_check.log 2>&1
		start_check=$(cat ${mha_base}/.status_check.log|awk '{print $4}')
		if [[ $start_check == "stopped(2:NOT_RUNNING)." ]]; then
			check_msg='MHA is Not Running'
		else
			echo -n 'Do you accept to MHA Stopped?(Y/N) : '
			read stop_apply
			case ${stop_apply} in
				Y|y)
					check_msg=$(masterha_stop --conf=${mha_conf})
				;;
				N|n)
					break
				;;
			esac
		fi
		rm -rf ${mha_base}/.status_check.log
	;;
	6)
		rm -rf ${mha_work}/mha.failover.complete
		masterha_check_status --conf=${mha_conf} > ${mha_base}/.status_check.log 2>&1
		start_check=$(cat ${mha_base}/.status_check.log|awk '{print $4}')
		if [[ $start_check == "running(0:PING_OK)," ]]; then
			check_msg='MHA is Now Running'
		else
			echo -n 'Do you accept to MASTER Switching?(Y/N) : '
			read switch_apply
			case ${switch_apply} in
				Y|y)
					echo 'MASTER Online Switching Start'
					for ((a=0;a<10;a++)); do
						echo -n '='
						sleep 1
					done
					masterha_master_switch --conf=${mha_conf} --master_state=alive --orig_master_is_new_slave
				;;
				N|n)
					break
				;;
			esac
		fi
		rm -rf ${mha_base}/.status_check.log
	;;
	7)
		clear
		exit
	;;
esac

done
