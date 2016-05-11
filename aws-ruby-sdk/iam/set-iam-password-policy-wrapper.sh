#!/bin/bash
#
# Use this shell wrapper for set-iam-password-policy.rb
# to set AWS environmental variables, if needed.
# Those variables should normally be set in your
# ~/.aws/credentials file, but they can be overidden here.
#

# Required script configuration:
export AWS_ACCESS_KEY_ID="put_your_access_key_here"
export AWS_SECRET_ACCESS_KEY="put_your_secret_key_here"

################################################
# Ensure we are using credentials set in this script,
# not set in credentials file, or elsewhere
################################################
unset AWS_DEFAULT_PROFILE
export AWS_DEFAULT_REGION=us-east-1

./set-iam-password-policy.rb
