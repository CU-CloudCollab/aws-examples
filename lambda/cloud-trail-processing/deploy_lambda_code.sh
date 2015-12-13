echo 1. update npm
npm install

echo 2. Zipping code for deployment
zip CloudTrailEventProcessing.zip -r CloudTrailEventProcessing.js node_modules/

echo 3. Uploading code via AWS CLI, assuming its an update
aws lambda update-function-code \
  --function-name CloudTrailEventProcessing  \
  --zip-file fileb://CloudTrailEventProcessing.zip
