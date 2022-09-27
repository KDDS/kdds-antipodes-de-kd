#!/usr/bin/env bash

# use secrets then -p "$(cat /run/secret/secretname"
echo /opt/mssql-tools/bin/sqlcmd -S mssql  -U sa -P $MSSQL_SA_PASSWORD -d master -i setup-db.sql -v PWD=$MSSQL_DEV_PASSWORD

sleep 30

for i in {1..50};
do
     /opt/mssql-tools/bin/sqlcmd -S mssql  -U sa -P $MSSQL_SA_PASSWORD -d master -i setup-db.sql -v PWD=$MSSQL_DEV_PASSWORD
    if [ $? -eq 0 ]
    then
        echo "SQL Server setup completed"
        break
    else
        echo "database not ready yet..."
        sleep 1
    fi
done 