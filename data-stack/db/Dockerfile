
FROM mcr.microsoft.com/mssql/server:2019-latest as base

# ENV ACCEPT_EULA=Y
# ENV MSSQL_IP_ADDRESS=0.0.0.0
# ENV MSSQL_PID=Developer

FROM base as mssqlbuild

USER root

WORKDIR /usr/src/app
COPY server.sh /usr/src/app
COPY entrypoint.sh /usr/src/app
COPY setup-db.sql /usr/src/app
RUN chmod 777 entrypoint.sh 
RUN chmod 777 server.sh 
 
EXPOSE 1433  

USER mssql

ENTRYPOINT [ "/bin/bash","./entrypoint.sh" ] 