![Plenus Platform Logo](https://raw.githubusercontent.com/plenus-cloud/backup-mysql/master/docs/img/plenus_platform_logo.png)

# backup-mysql
Docker container for mysql backup

## Usage

### Docker

    # run every hour command mysqldump --all-databases, mysql is at mysqlhostname:3306
    docker run -d -e SCHEDULE="* */1 * * *" -e MYSQLPASSWORD=mysecretpassword -e MYSQLHOST=mysqlhostname -e MYSQLUSER=root --name mysql-backup plenus/backup-mysql

    # run every hour command mysqldump for database MYSQLDB,  mysql is at mysqlhostname:33060
    docker run -d -e SCHEDULE="* */1 * * *" -e MYSQLPASSWORD=mysecretpassword -e MYSQLHOST=mysqlhostname -e MYSQLPORT=33060 -e MYSQLUSER=dbuser -e MYSQLDB=dbname --name mysql-backup plenus/backup-mysql

### Variables

SCHEDULE: schedule for backup, in cron format
MYSQLPASSWORD: password for MYSQLUSER
MYSQLUSER: mysql user to be used for backup
MYSQLDB: host name for mysql
MYSQLPORT: port for mysql
SKIPLOCK: set to 1 or true to add --skip-lock-tables to mysqldump

## Backup location

dump is created in file /dump/mysql.sql.gz (compressed with gzip).
