#!/usr/bin/env ruby

require 'rubygems'
require 'aws-sdk'

iam =iam = Aws::IAM::Client.new(region: 'us-east-1')

iam.list_users.users.each do |user_info|
  user = Aws::IAM::User.new(name: user_info.user_name, client: iam)
  puts "#{user.name} is missing an MFA device but has a logged in" if user.mfa_devices.count == 0 and user.password_last_used 
end
