# values(meta_data, keys=keys(meta_data)[1]) 
# https://stackoverflow.com/questions/7818970/is-there-a-dictionary-functionality-in-r

packages <- c("rvest", "stringr", "hash", "dplyr", "sqldf", "lattice", "lavaan", "readr")
install.packages(setdiff(packages, rownames(installed.packages())))  


# import the libraries
library('rvest')
library('stringr')
library("hash")
library('dplyr')
library('sqldf') 
library('odbc')
library('readr')

# setting datetime metadata for loading into database 
current_date  = format(strptime(as.character(Sys.Date()), format = "%Y-%m-%d"),"%m/%d/%Y")
load_date_time = format(strptime(as.character(Sys.time()), format = "%Y-%m-%d %H:%M:%S"),"%m/%d/%Y %H:%M:%S")

# creating a hash map reference of the metrics and its associated attributes to avoid breakage and cleaner coding
meta_data <- hash()
meta_data[['BKLN Intraday Stats']] <- list('Last Trade','Current IIV','Change','% Change','NAV at market close')
meta_data[['Yield']] <- list('SEC 30 Day Yield',	'Distribution Rate',	'12 Month Distribution Rate',	'30-Day SEC Unsubsidized Yield')
meta_data[['Prior Close']] <- list ('Closing Price','Bid/Ask Midpoint','Bid/Ask Prem/Disc','Bid/Ask Prem/Disc','Median Bid/Ask Spread')
meta_data[['Fund Characteristics *']] <- list ("3 Month LIBOR","Weighted Avg Price","Days To Reset","Weighted Avg Coupon","Weighted Avg Maturity","Yield to Maturity")

# read the web html
blkn <- read_html("https://www.invesco.com/us/financial-products/etfs/product-detail?audienceType=Investor&ticker=BKLN")

# Parse all the associated attributes and its values from the html . this will be referenced later from the hash created earlier to cut the 
# metrics and derive the value. Some values start at the start and some at the end of the string
metric_attributes <- blkn %>% 
  html_nodes(xpath='//*[@id="overview-details"]/div') %>% 
  html_children() %>%  
  html_elements("li") %>%  
  html_text(trim = TRUE)

# Parse all the metrics(table name) from the html to later use it for lookup with the hash map
metric_names <- blkn %>% 
  html_nodes(xpath='//*[@id="overview-details"]/div/h3') %>%  
  html_text(trim = TRUE)

# metric_attributes

# Parse all the time when metrics(table name) is updated from the html to later use it as an associated data
metric_times <- blkn %>% 
  html_nodes(xpath='//*[@id="overview-details"]/div/span') %>%  
  html_text(trim = TRUE)

# join the metric name and time to create a tibble and perform some cleaning


metrics_last_updated <- tibble(metric_names,metric_times)
ref_parsed_tibble <- as.data.frame(metrics_last_updated)
 
ref_parsed_tibble <- ref_parsed_tibble %>% 
  mutate(metric_times=trimws(str_replace_all(metric_times,'as of ','')) ) %>%
  mutate(metric_names_new=trimws(gsub('\r\n\t\t\t',' ',metric_names)) ) %>% 
  mutate(metric_names_new=trimws(gsub('  ',' ',metric_names_new)) ) %>% 
  mutate(metric_times=trimws(str_replace_all(metric_times,'as of','')) ) %>%
  mutate(metric_times=ifelse( metric_times=='',current_date,metric_times ))

 

# calculate total attributes parsed from the html
total_attributes = length(metric_attributes)
parsed_attributes = list()

# basic cleaning
for (attr in 1:total_attributes) {
  temp_row = str_replace_all(metric_attributes[attr],"[\r\n\t]", '') 
  temp_row = str_replace_all(temp_row,"SVO.*",'')
  temp_row = str_replace_all(temp_row,"as of ",' as of ')
  parsed_attributes <- append(parsed_attributes,temp_row) 
}

# dataframe by stitching the parsed data and referencing the hashmap
df  = NULL
for (metric in 1:length(keys(meta_data)))
{
  curr_metric = keys(meta_data)[metric]
  curr_all_attribs = values(meta_data, keys = curr_metric)
  for (attrib in 1:length(curr_all_attribs))
  {
    # cat("Searching value for : ", curr_all_attribs[[attrib]], " ! \n")
    for (idx in 1:length(parsed_attributes))
    {
      full_parsed_value = parsed_attributes[[idx]]
      
      # check if the reference attribute value is present in the parsed data
      flag = TRUE
      if (grepl(curr_all_attribs[[attrib]], full_parsed_value))
      {
        curr_value = trimws(str_replace_all(full_parsed_value, curr_all_attribs[[attrib]], ''))
        df = rbind(
          df,
          data.frame(
            table_type = trimws(curr_metric),
            metric_type = curr_all_attribs[[attrib]],
            metric_value = curr_value
          )
        )
        # message("\nFound ", curr_all_attribs[[attrib]] , ' with value ', curr_value)
        
        flag = FALSE
        
        break

      }

    }
  
    if (isTRUE(flag)) {
      message ('NOT found ', curr_all_attribs[[attrib]])
    }
    
  }
}

# transformation on the stitched data
finaldf <- df  %>%
  # clean the values that has last updated time by as of : create a separate date time column to save attribute level timing information
  mutate(last_updated =  trimws(str_split(metric_value, 'as of', simplify = TRUE)[, 2])) %>% 
  # separate out the exact value from a string with time information
  mutate(metric_value =  trimws(str_split(metric_value, 'as of', simplify = TRUE)[, 1])) %>% 
  # inner join with tibble created earlier to get the metric level timing
  inner_join(ref_parsed_tibble, by = c("table_type" = "metric_names_new"))  %>%
  # retrieving the metric level timing as a separate column
  mutate(last_updated = if_else(last_updated == "", metric_times, last_updated))  %>%
  # creating etl metadata , will be inserted as db load dte time
  mutate(db_load_datetime = load_date_time)  %>%
  #renamed_columns
  rename(
    metric_category = table_type,
    metric = metric_type,
    value = metric_value,
    metric_last_updated = last_updated,
    metric_category_last_updated = metric_times
  ) %>%
  select (!c(metric_names))

# the below code can be used if secrets are used.

#parsedpwd <- read_file("/run/secrets/db_dev_password")

conn <- DBI::dbConnect(odbc::odbc(),
                       Driver   = "ODBC Driver 17 for SQL Server",
                       Server   = "mssql",
                       Database = "development",
                       UID      = "antipodesDeveloper",
                       PWD      = "d3v_p@sswd",
                       Port     = 1433)  


dbWriteTable(conn, name='staging_belkin', value=finaldf,overwrite=TRUE, append= FALSE)  