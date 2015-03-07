#!/usr/bin/ksh
#
#####################################################################################################
#                S T A G I N G    O V E R L A Y - Source Apps Tasks                            		#
#                           1050_source_apps_processing.sh											#
#####################################################################################################
###########################################################################
# Modify settings below to suit your needs
###########################################################################
apposuser="applmgr"
appbkupbasepath="/orabackup/rmanbackups/"
basepath="/ovbackup/EBS_SCRIPTS/CLONE_SCRIPTS/"

### EMAIL
TOADDR="marni.srikanth@gmail.com"
CCADDR=" marni.srikanth@gmail.com,stackflow1@gmail.com"
RTNADDR="noreply@krispycorp.com"
#
trgappname=$1
trgapname=${trgappname// }
trgappname=`echo "$trgappname" | tr [a-z] [A-Z]`
 
case $trgappname in
	"PRODEBS")
		logfilename="$trgappname"_Overlay_$(date +%a)"_$(date +%F).log"
		srcappname="PRODEBS"
		apphomepath="/ovprd-ebsapp1/applmgr/PRODEBS/apps/"
		;;
    "CONV9EBS")
	    logfilename="$trgappname"_Overlay_$(date +%a)"_$(date +%F).log"
		srcappname="PRODEBS"
		apphomepath="/u01/applmgr/CONV9EBS/apps/"
		;;
        *)	
                echo ""
                echo ""
                echo " ====> Abort!!!. Invalid staging app name"
                echo ""
                exit 4
                ;;
esac
#################################################
# Default Configuration							#
#################################################
trgbasepath="${basepath}targets/"
logfilepath="${basepath}logs/"
functionbasepath="${basepath}function_lib/"
custfunctionbasepath="${basepath}custom_lib/"
custsqlbasepath="${custfunctionbasepath}sql/"
sqlbasepath="${functionbasepath}sql/"
rmanbasepath="${functionbasepath}rman/"
abendfile="$srcbasepath""$srcappname"/"$srcappname"_abend_step


####################################################################################################
#      add functions library                                                                       #
####################################################################################################
    
. ${basepath}function_lib/syncpoint.sh   
. ${basepath}function_lib/send_notification.sh
. ${basepath}function_lib/os_tar_gz_file.sh
. ${basepath}function_lib/os_delete_move_file.sh
. ${basepath}function_lib/os_user_check.sh
. ${basepath}function_lib/os_verify_or_make_directory.sh
. ${basepath}function_lib/os_verify_or_make_file.sh
#
########################################
#       VALIDATIONS                    #
########################################
#
if [ $# -lt 1 ]
then
	echo " ====> Abort!!!. Invalid database name for overlay"
        usage $0 :1000_overlay_staging  "[DATABASE NAME]"
        ########################################################################
        #   send notification                                                  #
        ########################################################################
        send_notification "$trgappname"_Overlay_abend "Invalid database name for replication" 3
        exit 3
fi
#

#
# Check user  
#
os_user_check ${osuser}
	rcode=$?
	if [ "$rcode" -gt 0 ]
	then
		echo "Not a valid user failed. Abrt!!! RC=" "$rcode"
		########################################
		#  update log file                     #
		########################################
		now=$(date "+%m/%d/%y %H:%M:%S")" ====> Check user failed. Abort!! \
		RC=""$rcode"       
		echo $now >>${logfilepath}${logfilename}
		syncpoint $trgappname $step "$LINENO"
		########################################################################
		#   send notification                                                  #
		########################################################################
		send_notification "$trgappname"_Overlay_abend "Not a valid user " 3
		echo "error.......Exit."
		echo ""
		exit $step
	fi
#
# Validate Directory
#
os_verify_or_make_directory ${logfilepath}
os_verify_or_make_directory ${trgbasepath}
os_verify_or_make_directory ${trgbasepath}${trgdbname}
os_verify_or_make_file ${abendfile} 0

#
restart=false
while read val1 val2
do
        stepnum=$val1
        linenum=$val2
        if [[ "$stepnum" !=  "0" ]]
        then
                restart=true
		echo ""
                echo "  RESTART LOCATION: "$stepnum" ,around line: "$linenum"" 
		echo "   SCRIPT LOCATION: ${basepath}$0"
                echo "TASK LOG  LOCATION: ${trgbasepath}${trgdbname}/"
                echo " RUN LOG  LOCATION: ${logfilepath}"
		echo ""
	else
		echo ""
                echo "   NORMAL LOCATION: "$stepnum" ,line: "$linenum""
		echo "   SCRIPT LOCATION: ${basepath}$0"
                echo "TASK LOG  LOCATION: ${trgbasepath}${trgdbname}/"
                echo " RUN LOG  LOCATION: ${logfilepath}"
		echo ""
		stepnum=`expr $stepnum + 50`
        fi
done < "$abendfile"
#
now=$(date "+%m/%d/%y %H:%M:%S")
echo $now >>$logfilepath$logfilename
#
now=$(date "+%m/%d/%y %H:%M:%S")" ====>  ########    $srcappname to $trgappname overlay has been started - PART1    ########"
echo $now >>$logfilepath$logfilename
#
for step in $(seq "$stepnum" 50 250)
do
        case $step in
        "50")
			echo "START TASK: $step send_notification"
			#####################################################################################
			#  send notification that APPS overlay started                                      #
			#  Usage: send_notification SUBJECT MSG CODE [1..3]                                 #
			#####################################################################################
			send_notification "$srcappname"_backup_started  "$srcappname backup started" 2 
			#
			########################################
			#  write an audit record in the log    #
			########################################
			now=$(date "+%m/%d/%y %H:%M:%S")" ====> Send start $srcappname apps backup Notification"
			echo $now >>$logfilepath$logfilename
			#
			echo "END   TASK: $step send_notification"
			;;
		"100")
			########################################
			#  check source apps status            #
			########################################
		"150")
			echo "START TASK: $step os_delete_move_file"
			########################################
			#  delete or move old backup		   #
			########################################
			now=$(date "+%m/%d/%y %H:%M:%S")" ====> Delete $srcappname old backups"
			echo $now >>$logfilepath$logfilename
			#
			os_delete_move_file M ${srcappname}.tar.gz ${srcappname}.tar.gz.$now
			#
	                rcode=$?
                        if [ "$rcode" -gt 0 ]
                        then
				rcode=$?
				echo "delete/move backup failed"
				now=$(date "+%m/%d/%y %H:%M:%S")" ====> Delete $srcappname old backups FAILD!!! RC=$rcode"
				echo $now >>$logfilepath$logfilename
				syncpoint $trgappname $step "$LINENO"
			        ########################################################################
			        #   send notification                                                  #
			        ########################################################################
#			        send_notification "$trgappname"_Overlay_abend "Delete $srcappname old backup failed" 3
				echo "error.......Exit."
                                echo ""
				exit $rcode
			fi
			echo "END   TASK: $step os_delete_move_file"
			;; 
		"200")
			echo "START TASK: $step start_rman_prod_backups"
			########################################
			#  delete old  bckup completed      #
			########################################
			now=$(date "+%m/%d/%y %H:%M:%S")" ====> Delete $srcappname old backups completed"
			echo $now >>$logfilepath$logfilename
			#
			########################################
			#  Start Source apps backups       #
			########################################
			now=$(date "+%m/%d/%y %H:%M:%S")" ====> Start $srcappname new backups"
			echo $now >>$logfilepath$logfilename
			#
			os_tar_gz_file ${srcappname}.tar.gz ${apphomepath} ${logfilepath}${srcappname}_tarbackup.log
			rcode=$?
			if [ $? -ne 0 ] # if RMAN connection fails
			then
				########################################
				#  update log file                     #
				########################################
				now=$(date "+%m/%d/%y %H:%M:%S")" ====> "$srcappname" backup FAILED. Abort!! RC=$rcode"
				echo $now >>$logfilepath$logfilename
				syncpoint $trgappname $step "$LINENO"
			        ########################################################################
			        #   send notification                                                  #
			        ########################################################################
#			        send_notification "$trgappname"_Overlay_abend "Source $srcappname apps backup failed" 3
				echo "error in  : os_tar_gz_file"
				echo ""
				exit 99
			fi
			echo "END   TASK: $step os_tar_gz_file"
			;;
		"250")
			########################################
			#  Source database backups completed   #
			########################################
			#
			########################################
			#  check source apps after backups #
			########################################
		"300")
                        echo "START TASK: $step end-of $srcappname app backup"
                        syncpoint $srcappname "0 " "$LINENO"
                        echo "END   TASK: $step end-of $srcappname app backup"
			;;
                   *)
                        echo "step not found - step: $step around Line ===> "  "$LINENO"
                ;;
        esac
done

