# antipodes-de-kd
Repository containing docker stack deployment and other relevant DE work

## Comments:

- **Stack** : Passwords are exposed but can be improved by using Docker secrets. The mounted secrets were difficult to test on local dev environment causing to permission issues. The compose file has been tested by mapping local path secrets in Windows dev env. Failed in Mac env due to permission issue. I removed it from the final deployment compose file to avoid any errors.

- **Stack** : Named volume is mounted. Create the volume before deployment p: docker volume create persist-data-vol OR create a volume as a service in swarm mode

- **Stack** : Ideally the workflow is to test the service and build the image locally or in a CI CD pipeline and push the images to a container registry. The stack can then be deployed into a cluster by using the compose file but having the image tag. In the attached docker compose file both the image and build tags are provided - they need to be used accordingly. The associated image was pushed to a local container registry for testing [ follow : https://docs.docker.com/engine/swarm/stack-deploy/ ]. Use **Build** : "." when **image** tag is used , to deploy into swarm.

- **Stack** : The folder structure  for stack deployment should be AS IS the structure in GIT folder data-stack. The secrets folder is optional and for local testing only in a non swarm environment

- **Stack** : user "admin" is a sudoer for all the login. The password is hardcoded in the dockerfile specification. So had to hardcode the password : Could have passed this value from environment var but it is not available during docker build time. So ARGs is the only option or write a SHELL script at the start/entrypoint to create the user if not exists using docker ENV vars. The requirement was not to use any arguments

- **Stack** : The artifact folder inside the dev is required to create the scheduler for R ETL script and save the data to table "staging_belkin" in schema::development . The crontab.sh is used to build the cron and is setup to fetch the data every minute. The logs can be found from the docker logs as the entrypoint is tail -f cron log.

- **R-etl** : The script uses a reference schema and the parsed data to effectively build the data. With constraint in time, I have to agree the R script is not polished and can be optimised a lot. The parsed data is not production grade clean but the script can be used to asess R capability. Also the check for pulling data when update is missing due to time constraint. However, in my opinion, we can keep pulling that data regularly whithout any such check (probably  at a longer interval of every 1 hour) and ingest into data warehouse layer as STAGING. From staging we can compare the previous run data and implement SCD type 2 to capture any historical data in separate tables or a single table (traditional data warehousing approach)

- **R-etl** : All the required statistics are always pushes to sql server via R script. However, the code uses a pre-captured schema to map the table name to its attributes. There can be a question on the scenario on how the data can be managed and be made available to data. To address that we can introduce a new task which collects all the attributes present on that page (line 33 : metric_attributes and line 40 : metric_names in data-stack/dev/artifacts/webScraper.R). A logic to parse the difference between the attributes pushed to database and the attributes present in those variable can be used to trigger an action which can ingest the new attributes into the pre-capture schema referenced in the R-script.

- **snow-sql** : 
  - The snow-sql folder has the query to calculate the aggregate
  - use connect.sh to connect to my trial snowflake account (Temporary). It uses then calculate-dividends.sql to rebuild database, waehouse and table schemas. Sample data from the image in the tasks have been introduced and the query is ran. A scenario with fsym_id ='CLO6GR-R' has been mocked to unit test the code.

- passwords (will be removed in a week) :  This section Will be deleted soon and ideally should be replaced by docker secret names

 - MSSQL :
    - sqldatabase: development
    - user: antipodesDeveloper
    - password: d3v_p@sswd

 - SUDOER :
    - username: admin
    - pwd: antipodesDeveloper
    - password: w0rld!
 
 - RSTUDIO :
    - user : rstudio
    - pwd : rstudio

 - Jupyter :
    - token : dockerst

  
