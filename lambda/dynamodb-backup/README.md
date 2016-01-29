# DyanmoDB Backup

### 0. Update bucket for storing backups

On or about line 23 you fill need to update your code with the name of the s3 bucket you whish to store your backups in.

```
Bucket: 'ccu-dynamo-backups'
```

### 1. Create zip to upload

1. grunt lambda_package
2. Zip will be created under the dist folder

### 2. Create a lambda function

1. Within lambda, press the 'Create a Lambda Function' button
2. Press the 'Skip' button to bypass the suggested blueprints
3. Enter the lambda function name DyanmoBackup
4. Select 'Node.js' as the Runtime
5. Upload the zip 
6. Under 'Handler' add 'Index.handler'

More [documentation on Lambda](https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html)

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
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:ListTables",
                "dynamodb:DescribeTable",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

This contains permissions for:

1. Saving logs for your lambda execution.
2. Stroring zipped dynamo backups from dynamo to S3.
3. List dynamo tables and get dynamo data

### Using Grunt

You can use grunt to invoke, pacakge and deploy the lambda function.  To test the function from the command line run:

```
grunt lambda_invoke
```

Once the lambda function has been created update Gruntfile.js with the arn of the function.  Once Gruntfile.js is up to 
date you can can simply deploy the function with:

```
grunt deploy
```

### Restore example

There is an example restore function in restore.js.  Example usage

```
./restore.js -b ccu-dynamo-backups -s alarms -t alarms1
```

The usage is:

```
[dynamodb-backup (master)]$ ./restore.js -h

  Usage: restore [options]

  Options:

    -h, --help                     output usage information
    -b, --bucketname <bucketname>  The name of the s3 bucket to restore from
    -t, --target <target>          The name of the table to create
    -s, --source <source>          The name of source file

```

All the options are required.  The source is the directory and name of the backup file.  The target is the name of the table to restore the data to.
