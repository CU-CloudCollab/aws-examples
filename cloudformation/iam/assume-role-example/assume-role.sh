#!/bin/bash

# Example scrip that assumes a role in another account.

ASSUME_ROLE="arn:aws:iam::999999999999:role/shib-dba"
ROLE_SESSION_NAME="mysession"
TMP_FILE="assume-role-output.tmp"
DURATION_SECONDS=900
AWS_REGION="us-east-1"

echo "Assume role: ${ASSUME_ROLE}"

aws sts assume-role --output json --duration-seconds $DURATION_SECONDS --role-arn ${ASSUME_ROLE} --role-session-name ${ROLE_SESSION_NAME} > ${TMP_FILE}

echo "Assume role response:"
cat ${TMP_FILE}

ACCESS_KEY_ID=$(jq -r ".Credentials.AccessKeyId" < ${TMP_FILE})
SECRET_ACCESS_KEY=$(jq -r ".Credentials.SecretAccessKey" < ${TMP_FILE})
SESSION_TOKEN=$(jq -r ".Credentials.SessionToken" < ${TMP_FILE})
EXPIRATION=$(jq -r ".Credentials.Expiration" < ${TMP_FILE})

echo "Retrieved temp access key ${ACCESS_KEY} for role ${ASSUME_ROLE}. Key will expire at ${EXPIRATION}."

CMD="aws rds describe-db-instances --region us-east-1"

echo "AWS CLI command: $CMD"
OUTPUT_FILE="run-command-output.tmp"
AWS_ACCESS_KEY_ID=${ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY} AWS_SESSION_TOKEN=${SESSION_TOKEN} \
  ${CMD} > ${OUTPUT_FILE}

echo "Command output:"
cat ${OUTPUT_FILE}
