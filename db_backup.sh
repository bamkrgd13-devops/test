#!/bin/bash

dbList='corvus@corvus@secret@172.16.9.26 corvus_test@corvus@secret@172.16.9.26'
{
echo `date` "Starting"
err_count=0
for i in ${dbList}
do
  db_name=`echo $i | awk -F@ '{print $1}'`
  db_user=`echo $i | awk -F@ '{print $2}'`
  db_pass=`echo $i | awk -F@ '{print $3}'`
  db_host=`echo $i | awk -F@ '{print $4}'`
  echo `date` "Starting back up ${db_name}"
  mysqldump -h $db_host -u $db_user --single-transaction --column-statistics=0 --skip-lock-tables -p$db_pass $db_name > ./${db_name}_backup_`date +%d%m%Y`.sql
  if [ $? -ne 0 ]
  then err_count=`expr $err_count + 1`
  else echo "Successfully backed up ${db_name}"
  fi
done
if [ "$err_count" != "0" ]
then
  for i in `ls *.sql`
  do
     rm -f ./${i}
  done
  echo `date` "An error occured. Stopping"
  exit
fi

echo `date` "Starting to add dumps to the archive"
tar -zcvf ./db_backup_`date +%d%m%Y`.tar.gz ./*.sql
if [ $? -ne 0 ]
then
  rm -f ./db_backup_`date +%d%m%Y`.tar.gz
  echo `date` "An error occured while creating archive."
else echo `date` "Starting to check archive integrity"
     tar -tzf ./db_backup_`date +%d%m%Y`.tar.gz
     if [ $? -ne 0 ]
     then echo `date` "Archive integrity checking completed with error"
           rm -f ./db_backup_`date +%d%m%Y`.tar.gz
     else echo `date` "Starting to move archive to the backups directory"
          mv -f ./db_backup_`date +%d%m%Y`.tar.gz /backups
          if [ $? -ne 0 ]
          then echo `date` "An error occured while moving archive to the backups directory"
               rm -f /backups/db_backup_`date +%d%m%Y`.tar.gz
               rm -f ./db_backup_`date +%d%m%Y`.tar.gz
          else echo `date` "Successfully moved archive to the backups directory"
          fi
     fi
fi
for i in `ls *.sql`
do
  rm -f ./${i}
done
echo `date` "Stopping"
} > ./db_backup.log 2>&1
