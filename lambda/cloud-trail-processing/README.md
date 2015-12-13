# CloudTrail Processing

### 0. Create zip to upload

1. npm install
2. zip -r CloudTrailEventProcessing.zip CloudTrailEventProcessing.js node_modules

### 1. Create a lambda function

1. Within lambda, press the 'Create a Lambda Function' button
2. Press the 'Skip' button to bypass the suggested blueprints
3. Enter the lambda function name CloudTrailEventProcessing
4. Select 'Node.js' as the Runtime
5. Upload the zip (see deploy script)
6. Under 'Handler' add 'CloudTrailEventProcessing.handler'

More [documentation on Lambda](https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html)

### 2. Turn on CloudTrail for your region

1. Turn on CloudTrail.
2. Create a new Amazon S3 bucket for storing your log files, or specify an existing bucket where you want the log files delivered.
3. Create a new Amazon SNS topic in order to receive notifications when new log files are delivered.

More [documentation on creating a Trail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-create-and-update-a-trail.html)

[Script for setting up CloudTrail](https://github.com/CU-CloudCollab/aws-examples/blob/master/aws-cli/cloud-trail/create-cloud-trail-all-regions.sh)

### 3. Configure the access policy for your lambda role

Your lambda function will run as an IAM role.  This is where we configure the permissions required.

#### Lambda function master policy
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "arn:aws:sns:us-east-1:111111111111:cloud-trail-alerts"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
```

This contains permissions for:

1. Saving logs for your lambda execution.
2. Retrieving zipped CloudTrail log items from S3.
3. publish events to SNS
4. updating r53 entries

### 4. Hook up the Lambda function to the s3 events for cloud trail

You will need to add permission to the lambda function to allow s3 to invoke it.

```json
aws lambda add-permission \
--function-name CloudTrailEventProcessing \
--region us-east-1 \
--statement-id Id-1 \
--action "lambda:InvokeFunction" \
--principal s3.amazonaws.com \
--source-arn arn:aws:s3:::cu-cs-sandbox \
--source-account 111111111111
```
### 5. Setup s3 bucket to trigger lambda event 

Now you will need to go into the s3 bucket configuration and enable notifications to the lambda function 
using the lambda ARN, ie arn:aws:lambda:us-east-1:111111111111:function:CloudTrailEventProcessing.
