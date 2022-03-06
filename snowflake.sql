// create datawarehouse 
CREATE OR REPLACE WAREHOUSE mywarehouse WITH
  WAREHOUSE_SIZE='X-SMALL'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

// create database
CREATE OR REPLACE DATABASE ETL_PIPELINE;

// create DIMDATE table
CREATE OR REPLACE TABLE DIMDATE (
    DATETIME_SKEY TIMESTAMP,
    PRIMARY KEY (DATETIME_SKEY)
);

// create DIMPLATFORM table
CREATE OR REPLACE TABLE DIMPLATFORM (
    PLATFORM_SKEY INTEGER NOT NULL,
    PLATFORM_TYPE VARCHAR(200) NOT NULL,
    PRIMARY KEY (PLATFORM_SKEY)
);

// create DIMSITE table
CREATE OR REPLACE TABLE DIMSITE (
    Site_SKEY INTEGER NOT NULL,
    Site VARCHAR(200) NOT NULL,
    PRIMARY KEY (Site_SKEY)
);

// create DIMVIDEO table
CREATE OR REPLACE TABLE DIMVIDEO (
    Video_SKEY INTEGER NOT NULL,
    Video_Title TEXT NOT NULL,
    PRIMARY KEY (Video_SKEY)
);

// create FACTTABLE
CREATE OR REPLACE TABLE FACTTABLE (
    DATETIME_SKEY TIMESTAMP REFERENCES DIMDATE(DATETIME_SKEY),
    Platform_SKEY INTEGER REFERENCES DIMPLATFORM(Platform_SKEY),
    Site_SKEY INTEGER REFERENCES DIMSITE(Site_SKEY),
    Video_SKEY INTEGER REFERENCES DIMVIDEO(Video_SKEY),
    events VARCHAR2(150 BYTE) NOT NULL
);

// Create a file format 
CREATE OR REPLACE FILE FORMAT DataPipeline_CSV_Format
    TYPE = 'CSV'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI'
    skip_header = 1
    field_delimiter = ','
    record_delimiter = '\\n'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

// create a external stage
CREATE OR REPLACE STAGE S3_to_Snowflake_Stage
    URL="S3://dst-bucket-snowpipeline"
    CREDENTIALS = (AWS_KEY_ID = '**************' AWS_SECRET_KEY = '**************')
    file_format = DataPipeline_CSV_Format;

// create pipes
CREATE OR REPLACE PIPE DimDate_Pipe
    AUTO_INGEST = TRUE 
    AS COPY INTO DIMDATE 
    FROM @S3_to_Snowflake_Stage/dimdate/
    FILE_FORMAT = (FORMAT_NAME = DataPipeline_CSV_Format);
    
CREATE OR REPLACE PIPE Dimplatform_Pipe
    AUTO_INGEST = TRUE 
    AS COPY INTO DIMPLATFORM 
    FROM @S3_to_Snowflake_Stage/dimplatform/
    FILE_FORMAT = (FORMAT_NAME = DataPipeline_CSV_Format);
    
CREATE OR REPLACE PIPE DimSite_Pipe
    AUTO_INGEST = TRUE 
    AS COPY INTO DIMSITE 
    FROM @S3_to_Snowflake_Stage/dimsite/
    FILE_FORMAT = (FORMAT_NAME = DataPipeline_CSV_Format);
    
CREATE OR REPLACE PIPE DimVideo_Pipe
    AUTO_INGEST = TRUE 
    AS COPY INTO DIMVIDEO 
    FROM @S3_to_Snowflake_Stage/dimvideo/
    FILE_FORMAT = (FORMAT_NAME = DataPipeline_CSV_Format);

CREATE OR REPLACE PIPE FactTable_Pipe
    AUTO_INGEST = TRUE 
    AS COPY INTO FACTTABLE 
    FROM @S3_to_Snowflake_Stage/facttable/
    FILE_FORMAT = (FORMAT_NAME = DataPipeline_CSV_Format);

// PIPES COMMAND
SHOW PIPES; -- check pipes to get notification_channel url
SELECT SYSTEM$PIPE_STATUS('<PIPE NAME>'); -- Check Pipe Status if need
SELECT * FROM table(information_schema.copy_history(table_name=>'<TABLE NAME>', start_time=> dateadd(hours, -1, current_timestamp()))); -- Show PIPE COPY history in specific table 
ALTER PIPE <PIPE NAME> REFRESH; -- REFRESH PIPE 

// EXTERNAL STAGE COMMAND
LIST @S3_to_Snowflake_Stage; -- Check if files exists in external stage 
REMOVE '@S3_to_Snowflake_Stage/dimdate/date.csv'; -- remove single file from external stage 
REMOVE @S3_to_Snowflake_Stage pattern='.*.csv'; -- remove all files from external stage 

// save notification_channel url for S3 Event Notification
arn:aws:sqs:ap-southeast-2:123456789012:sf-snowpipe-**************-**************