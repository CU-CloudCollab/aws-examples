#/bin/bash

CLOUDTRAIL_S3_BUCKET="your_S3_bucket_name"
REGION_FOR_GLOBAL_EVENTS="us-east-1"
PROFILE="default"
ACCOUNTNUM="your_account_number"

sed "s/BUCKETNAME/${CLOUDTRAIL_S3_BUCKET}/g" cloud-trail-policy.json.tmpl > cloud-trail-policy.json
sed -ie "s/ACCOUNTNUM/${ACCOUNTNUM}/g" cloud-trail-policy.json

aws --profile $PROFILE s3 mb s3://$CLOUDTRAIL_S3_BUCKET
aws --profile $PROFILE s3api put-bucket-policy --bucket $CLOUDTRAIL_S3_BUCKET --policy file://cloud-trail-policy.json

aws --profile $PROFILE cloudtrail create-trail --name main-trail --s3-bucket-name $CLOUDTRAIL_S3_BUCKET --include-global-service-events --is-multi-region-trail
aws --profile $PROFILE cloudtrail start-logging --name main-trail
