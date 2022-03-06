# Overview of the solution
The project includes a local environment to inspect the data and deploy the stack using the AWS S3, Lambda in Serverless Framework, AWS SQS, and Snowflake Snowpipe. 

The deployment includes an object-based event that triggers an AWS Lambda function. The function ingests and stores the raw data from an external source, transforms the content, and saves clean information. 

The raw and clean data is stored in an S3 destination bucket with SQS event notifications, which will deliver data to snowpipe.

The following diagram illustrates my architecture:

![alt text](https://github.com/miaaaalu/AWS-Lambda-to-Snowflake-Data-Cloud-ETL-Integration-with-Serverless/blob/master/data_pipeline.jpg?raw=true)

The solution includes the following high-level steps:

1. Design the star schema for the source file 
2. Snowflake Snowpipe Configuration
3. Build and test the ETL process
2. Inspect the function and the AWS Cloudformation template and deploy in Serverless Framework
5. Create an Event Notification for the S3 destination buck

# Test Environment 
```powershell
* System: macOS Big Sur Version 11.5.2

* Programming: Python 3.8, Snowflake SQL

* Tools: Snowflake, Cloud Service Provider: AWS (S3, Lambda, and SQS), Serverless Framework
```

# Process Workflow 
## Preparation
### AWS
```powershell
1. Create source bucket in S3
2. Create deploy bucket for the serverless package in S3 
3. Create an IAM User for snowflake with S3 full access policies
```
### Python 
```powershell
3.8 preferable
```
## Step 1 — Table Design 
```powershell
For details check table_design.ipynb
```

## Step 2 — Snowflake Snowpipe Configuration
```powershell
1. Database Creation
2. Tables Creation (5 tables in this project)
3. File Format Creation with AWS Credentials
4. External Stage Creation
4. Pipes Creation 

For details check snowflake.sql
```

## Step 3 — Serverless Framework Deploy

*Serverless Framework is open source software that builds, compiles, and packages code for serverless deployment, and then deploys the package to the cloud. With Python on AWS, for example, Serverless Framework creates the self-contained Python environment, including all dependencies.*

### 1. Serverless Project Initialization
```powershell
% serverless create --template aws-python3 --path {project_folder}
```

### 2. Open the project in VScode
```powershell
% open -a “Visual Studio Code” ${project_folder}
```

### 3. Serverless Plugin Installation
```powershell
# Instal Serverless Prune Plugin 
% sudo sls plugin install -n serverless-prune-plugin

# Install serverless python requirements (https://github.com/UnitedIncome/serverless-python-requirements)
% sudo sls plugin install -n serverless-python-requirements

# Install serverless dotenv plugin
% sudo npm i -D serverless-dotenv-plugin
```
### 4. Modify .python file for ETL Process
```powershell
# Rename python file
% mv handler.py ${project_handle}.py

# Handle your Python packaging
By default, pandas library is not available in AWS Lambda Python environments. 
For using pandas library in Lambda function, a requirements.txt needs to be attached.
OR add Python pandas layer to AWS Lambda in serverless.yml.

# option 1: attach a requirements.txt with needed library
% touch requirements.txt
% echo “pandas” >> requirements.txt
% pip install -r requirements.txt

# option 2: add the pandas layer from Klayers in serverless.yml (recommend)
source from Klayers: https://github.com/keithrozario/Klayers/tree/master/deployments/python3.8/arns 

# ETL Process
a. Load raw file 
b. Data Cleaning
c. Data Washing
b. Data transformation for table DIMDATE, DIMPLATFORM, DIMSITE, DIMVIDEO, and FACTTABLE
d. Load Data into staging folders - DIMDATE, DIMPLATFORM, DIMSITE, DIMVIDEO, and FACTTABLE

For details check etl_process.py
```
### 5. Create .env file and put environment variables if need
```env
APPLICATION = ${your project name}
STAGE = ${your stage}
REGION = ${your region}
TZ_LOCAL = ${your timezone}
```
### 6. Modify serverless.yml file
```Powershell
For details check serverless.yml
```

### 7. Deploy
```Powershell
# Deploy to aws 
% sls deploy
```

## Step 4 — Add Event Notification for S3 Bucket

```
This notification informs Snowpipe via an SQS queue when files are ready to load.

Please note the SQS queue ARN from the notification_channel column once you execute 「show pipes」 command. 

Copy the ARN to a notepad.

Then paste on the Event Notification for destination S3 bucket.
```