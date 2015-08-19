#/bin/bash

CLOUDTRAIL_S3_BUCKET="your_S3_bucket_name"
REGION_FOR_GLOBAL_EVENTS="us-east-1"
PROFILE="default"
ACCOUNTNUM="your_account_number"

# get list of regions for account
regionlist=($(aws ec2 describe-regions --query Regions[*].RegionName --output text))

sed "s/BUCKETNAME/${CLOUDTRAIL_S3_BUCKET}/g" cloud-trail-policy.json.tmpl > cloud-trail-policy.json
sed -ie "s/ACCOUNTNUM/${ACCOUNTNUM}/g" cloud-trail-policy.json


aws --profile $PROFILE s3 mb s3://$CLOUDTRAIL_S3_BUCKET
aws --profile $PROFILE s3api put-bucket-policy --bucket $CLOUDTRAIL_S3_BUCKET --policy file://cloud-trail-policy.json

for region in "${regionlist[@]}"; do if [ $region = $REGION_FOR_GLOBAL_EVENTS ]; then aws --profile $PROFILE --region $region cloudtrail create-trail --name $region --s3-bucket-name $CLOUDTRAIL_S3_BUCKET --include-global-service-events; else aws --profile $PROFILE --region $region cloudtrail create-trail --name $region --s3-bucket-name $CLOUDTRAIL_S3_BUCKET --no-include-global-service-events; fi; done
for region in "${regionlist[@]}";  do aws --profile $PROFILE --region $region cloudtrail start-logging --name $region; done

