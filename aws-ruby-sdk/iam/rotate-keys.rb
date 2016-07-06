#!/usr/bin/env ruby

require 'aws-sdk'
require 'parseconfig'
require 'fileutils'

AWS_CONFIG_FILE = "/.aws/credentials"
Aws.config.update(region: 'us-east-1')

# Backup the credentials files before we do anything to it
filename = Dir.home + AWS_CONFIG_FILE
FileUtils.copy(filename, filename + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))

# get the current profiles from the default AWS credentials file
config = ParseConfig.new(filename)

config.groups.each do |group|
  next if group =~ /saml/;
  puts group

  # update the aws config to use the credetials for this group
  Aws.config.update({
    credentials: Aws::Credentials.new(config.params[group]['aws_access_key_id'],
                                      config.params[group]['aws_secret_access_key'])
  })

  # create the iam client and get the last time the key was used
  iam = Aws::IAM::Client.new
  resp = iam.get_access_key_last_used({
    access_key_id: config.params[group]['aws_access_key_id'], # required
  })

  # now grab the user name form the response
  user = resp.user_name
  puts "\tcreating new keys for #{user}..."

  # create and store new keys
  resp = iam.create_access_key({
    user_name: user,
  })

  new_access_key_id = resp.access_key.access_key_id
  new_secret_access_key = resp.access_key.secret_access_key

  # give time for the new credentials to become active
  sleep 5

  # use the new credentials to delete the old credentials to ensure they are working
  puts "\tusing new keys for #{user}..."

  # use new credentials
  Aws.config.update({
    credentials: Aws::Credentials.new(new_access_key_id,
                                      new_secret_access_key)
  })

  # delete the users old credentials
  puts "\tdeleting old keys for #{user}..."
  iam = Aws::IAM::Client.new
  resp = iam.delete_access_key({
    user_name: user,
    access_key_id: config.params[group]['aws_access_key_id'],
  })

  # update the config for this group
  config.add_to_group(group, 'aws_access_key_id', new_access_key_id)
  config.add_to_group(group, 'aws_secret_access_key', new_secret_access_key)

  # Write the updated config file
  file = File.open(filename, 'w')
  config.write(file, false)
  file.close

end
