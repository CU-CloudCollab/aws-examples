#!/usr/bin/env ruby
######################################
#
# Sets a default password policy, in part to ensure
# that CloudCheckr won't generate a bunch of warnings
# surrounding lack of a password policy.
#
# Since generally no IAM users should have passwords,
# this doesn't improve anything, exept to hush the
# CloudCheckr warnings.
#
######################################

require 'aws-sdk'

# Relies on  ~/.aws/credentials file or
# environmental varaible settings
@iam = Aws::IAM::Client.new

resp = @iam.update_account_password_policy({
  minimum_password_length: 8,
  require_symbols: true,
  require_numbers: true,
  require_uppercase_characters: true,
  require_lowercase_characters: true,
  allow_users_to_change_password: true,
  max_password_age: 90,
  password_reuse_prevention: 3,
  hard_expiry: false
})
