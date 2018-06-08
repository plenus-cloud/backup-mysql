![Plenus Platform Logo](https://raw.githubusercontent.com/plenus-cloud/backup-mysql/master/docs/img/plenus-platform-logo.png)

# backup-mysql
Docker container for mysql backup

## Usage

### Docker

    # run every hour command mysqldump --all-databases, mysql is at mysqlhostname:3306
    docker run -d -e SCHEDULE="* */1 * * *" -e MYSQLPASSWORD=mysecretpassword -e MYSQLHOST=mysqlhostname -e MYSQLUSER=root --name mysql-backup plenus/backup-mysql

    # run every hour command mysqldump for database MYSQLDB,  mysql is at mysqlhostname:33060
    docker run -d -e SCHEDULE="* */1 * * *" -e MYSQLPASSWORD=mysecretpassword -e MYSQLHOST=mysqlhostname -e MYSQLPORT=33060 -e MYSQLUSER=dbuser -e MYSQLDB=dbname --name mysql-backup plenus/backup-mysql

## Backup location

dump is created in file /dump/mysql.sql.gz (compressed with gzip).
