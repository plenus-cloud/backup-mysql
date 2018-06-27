#!/bin/bash
set -o pipefail

# cron schedule
# must be in crontab format
if [ -z "${SCHEDULE}" ]; then
  echo "env var SCHEDULE must be set in crontab format"
  echo "Format: minute hour dom month wday"
  echo "Ex."
  echo "SCHEDULE='*/5 * * * *'"
  exit 1
fi

# CRONCMD: if empty use default command to backup mysql
# otherwise use this value as backup command, escape \$ to use env vars

# MYSQLDB: db to backup, if empty dump all databases

# mysql hostname, default to mysql
if [ -z "${MYSQLHOST}" ]; then
  MYSQLHOST="mysql"
fi

# mysql port, default to 3306
if [ -z "${MYSQLPORT}" ]; then
  MYSQLPORT=3306
fi

# mysql username, default to root
if [ -z "${MYSQLUSER}" ]; then
  MYSQLUSER="root"
fi

# mysql password
if [ -z "${MYSQLPASSWORD}" ]; then
  echo "env MYSQLPASSWORD must contain mysql password"
  exit 1
fi

DUMPOPTIONS=""
# mysql dump options
if [ -n "${SKIPLOCK}" ]; then
  if [ "${SKIPLOCK}" = "1" ] || [ "${SKIPLOCK}" = "true" ]; then
    DUMPOPTIONS="${DUMPOPTIONS} --skip-lock-tables"
  fi
fi

# write cron schedule
echo "${SCHEDULE}        root    /usr/local/bin/task0.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/task0
echo "# An empty line is required at the end of this file for a valid cron file." >> /etc/cron.d/task0
chmod 644 /etc/cron.d/task0
# write cron job command
echo "#!/bin/bash" > /usr/local/bin/task0.sh
echo date >> /usr/local/bin/task0.sh
echo "echo \"Running \$0\"" >> /usr/local/bin/task0.sh
echo "echo \"--- BEGIN COMMAND OUTPUT\"" >> /usr/local/bin/task0.sh
echo "echo \"Cleaning up /dump/ ...\"" >> /usr/local/bin/task0.sh
echo "find /dump -maxdepth 1 ! -wholename '/dump' ! -wholename '/dump/lost+found' -exec rm -fr {} \;" >> /usr/local/bin/task0.sh
if [ -z "${CRONCMD}" ]; then
  if [ -z "${MYSQLDB}" ]; then
    echo "echo \"Dumping databases...\"" >> /usr/local/bin/task0.sh
    echo "mysqldump -h ${MYSQLHOST} -P ${MYSQLPORT} -u ${MYSQLUSER} -p\"${MYSQLPASSWORD}\" --all-databases ${DUMPOPTIONS} | gzip -c > /dump/mysql.sql.gz" >> /usr/local/bin/task0.sh
    echo "DUMP_RC=\${PIPESTATUS[0]}" >> /usr/local/bin/task0.sh
    echo "if [ \${DUMP_RC} -ne 0 ]; then" >> /usr/local/bin/task0.sh
    echo "  echo \"Error code \${DUMP_RC} in databases dump, retrying dump with -f...\"" >> /usr/local/bin/task0.sh
    echo "  mysqldump -h ${MYSQLHOST} -P ${MYSQLPORT} -u ${MYSQLUSER} -p\"${MYSQLPASSWORD}\" -f --all-databases ${DUMPOPTIONS} | gzip -c > /dump/mysql.sql.gz" >> /usr/local/bin/task0.sh
    echo "fi" >> /usr/local/bin/task0.sh
  else
    echo "echo \"Dumping database ${MYSQLDB}...\"" >> /usr/local/bin/task0.sh
    echo "mysqldump -h ${MYSQLHOST} -P ${MYSQLPORT} -u ${MYSQLUSER} -p\"${MYSQLPASSWORD}\" ${DUMPOPTIONS} ${MYSQLDB} | gzip -c > /dump/mysql.sql.gz" >> /usr/local/bin/task0.sh
    echo "DUMP_RC=\${PIPESTATUS[0]}" >> /usr/local/bin/task0.sh
    echo "if [ \${DUMP_RC} -ne 0 ]; then" >> /usr/local/bin/task0.sh
    echo "  echo \"Error code \${DUMP_RC} in databases dump, retrying dump with -f...\"" >> /usr/local/bin/task0.sh
    echo "  mysqldump -h ${MYSQLHOST} -P ${MYSQLPORT} -u ${MYSQLUSER} -p\"${MYSQLPASSWORD}\" -f ${DUMPOPTIONS} ${MYSQLDB} | gzip -c > /dump/mysql.sql.gz" >> /usr/local/bin/task0.sh
    echo "fi" >> /usr/local/bin/task0.sh
  fi
else
  echo "${CRONCMD}" >> /usr/local/bin/task0.sh
fi
echo "echo \"--- END COMMAND OUTPUT\"" >> /usr/local/bin/task0.sh
echo "echo \"\"" >> /usr/local/bin/task0.sh
chmod 755 /usr/local/bin/task0.sh

# Start cron
cron -L 15
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start cron: $status"
  exit $status
fi
date
echo "cron started"
echo ""

# Start logging
tail -f /var/log/cron.log &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start logging: $status"
  exit $status
fi
date
echo "logging started"
echo ""

# check if processes are alive, if not exit
while /bin/true; do
  ps -e -o command | grep "^cron" > /dev/null 2>&1
  CRON_STATUS=$?
  ps -e -o command | grep "^tail" > /dev/null 2>&1
  LOGGING_STATUS=$?
  # If the greps above find anything, they will exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $CRON_STATUS -ne 0 ]; then
    date
    echo "cron process terminated, exiting"
    exit 2
  fi
  if [ $LOGGING_STATUS -ne 0 ]; then
    date
    echo "logging process terminated, exiting"
    exit 3
  fi
  sleep 20
done
