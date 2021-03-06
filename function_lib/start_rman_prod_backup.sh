start_rman_prod_backup()
{
dbname=$1
ldbname=`echo "$dbname" | tr [A-Z] [a-z]`
#
orasid="$dbname"1
export ORACLE_SID="$orasid"
export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/dbhome_1
export NLS_DATE_FORMAT='DD-MM-RRRR HH24:MI:SS'
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_BASE=/u01/app/oracle
#
if [ $dbname == "DBM01" ]
then
        orasid="$ldbname"1
        export ORACLE_SID="$orasid"
        export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/dbhome_1
        export NLS_DATE_FORMAT='DD-MM-RRRR HH24:MI:SS'
        export PATH=$ORACLE_HOME/bin:$PATH
        export ORACLE_BASE=/u01/app/oracle
fi
#
case $dbname in
        "DPGN")
                rman target / @/u01/app/oracle/scripts/refresh/source/DPGN/DPGN_rman.rcv    \
                                > /u01/app/oracle/scripts/refresh/logs/DPGN_rman.log
                ;;
        "DPTP")
                rman target / @/u01/app/oracle/scripts/refresh/source/DPTP/DPTP_rman.rcv    \
                                > /u01/app/oracle/scripts/refresh/logs/DPTP_rman.log
                ;;
        "DBM01")
                rman target / @/u01/app/oracle/scripts/refresh/source/DBM01/DBM01_rman.rcv  \
                                > /u01/app/oracle/scripts/refresh/logs/DBM01_rman.log
                ;;
        *)
                echo "wrong backup";;
esac
}
