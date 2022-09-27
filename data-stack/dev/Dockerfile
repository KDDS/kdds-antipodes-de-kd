FROM ubuntu:20.04 AS base
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y 
RUN apt-get install -y wget make build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev
RUN apt-get install  -y cron mcrypt   gdebi-core  libcurl4-openssl-dev r-cran-rodbc libxml2-dev sudo  

RUN apt-get install -y curl apt-transport-https \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev 

ARG servicetype
ARG password
ARG username

# In production the password can be use used from secrets (file or external). 
# I have kept it simple as it is hard to replicate swarm environment
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1001  -p "$(openssl passwd -crypt w0rld!)"  admin
USER root

FROM base as jbuild
RUN wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz
RUN mkdir -p /home/python3
RUN mv Python-3.10.6.tgz /home/python3
WORKDIR  "/home/python3/"
RUN tar -xf Python-3.10.6.tgz
WORKDIR  "/home/python3/Python-3.10.6"
RUN ./configure --enable-optimizations
RUN make -j $(nproc)
RUN make altinstall
RUN apt-get -y install python3-pip
RUN pip install jupyterlab
EXPOSE 8888

FROM base as rbase
RUN apt-get install -y  r-base
RUN Rscript -e 'install.packages("rvest")'
RUN Rscript -e 'install.packages("stringr")'
RUN Rscript -e 'install.packages("hash")'
RUN Rscript -e 'install.packages("dplyr")'
RUN Rscript -e 'install.packages("sqldf")'
RUN Rscript -e 'install.packages("RODBC")'
RUN Rscript -e 'install.packages("DBI")'
RUN Rscript -e 'install.packages("readr")'
RUN Rscript -e 'install.packages("odbc", repos = "https://cloud.r-project.org")'

FROM rbase as rstdbuild
RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2022.07.2-576-amd64.deb
RUN gdebi --non-interactive rstudio-server-2022.07.2-576-amd64.deb
RUN useradd -m -d /home/rstudio -g rstudio-server rstudio && echo rstudio:rstudio | chpasswd
RUN chown -R rstudio:rstudio-server /home/rstudio
EXPOSE 8787  

FROM rbase as schbuild
WORKDIR /home/rstudio/jobs
COPY ./artifacts/crontab.sh .
COPY ./artifacts/webScraper.R .
RUN chmod a+x crontab.sh 



