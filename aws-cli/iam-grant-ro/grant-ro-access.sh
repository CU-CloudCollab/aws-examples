#!/bin/bash
#
# Grant cross-account RO access to the the shib-admin group in
# a different AWS account.
#
# Like all AWS CLI commands, it assumes that you've already configured
# your credentials.
#
# To run:
# 1) Edit TARGET_ACCOUNT below to be the account you wish to allow access FROM
# 2) At command line: ./grant-ro-access.sh.

ROLE_NAME=cit-cloud-team-ro
TARGET_ACCOUNT=123456789012

cp assume-role-policy.json /tmp/assume-role-policy.json
sed -ie "s/ACCOUNT_PLACEHOLDER/$TARGET_ACCOUNT/g" /tmp/assume-role-policy.json

aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file:///tmp/assume-role-policy.json --profile training

aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --profile training
