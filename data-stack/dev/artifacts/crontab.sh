#!/usr/bin/env bash
mkdir -p /home/rstudio/jobs/logs
# Ensure the log file exists
touch /home/rstudio/jobs/logs/crontab.log

# Ensure permission on the command
chmod -R a+x /home/rstudio/jobs 
 
# Added a cronjob in a new crontab
echo "* * * * * Rscript  /home/rstudio/jobs/webScraper.R >> /home/rstudio/jobs/logs/crontab.log 2>&1" > /etc/crontab

# Registering the new crontab
crontab /etc/crontab

# Starting the cron
/usr/sbin/service cron start

# Displaying logs
# Useful when executing docker-compose logs mycron
tail -f /home/rstudio/jobs/logs/crontab.log