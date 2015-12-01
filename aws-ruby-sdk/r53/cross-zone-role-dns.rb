#!/usr/bin/env ruby

require 'rubygems'
require 'aws-sdk'

Aws.config = {credentials: Aws::SharedCredentials.new(profile_name: "pidash"), region: "us-east-1"}

sts = Aws::STS::Client.new

r53_creds = sts.assume_role({
  role_arn: "arn:aws:iam::280534934474:role/DNS-pidash.cornell.edu",
  role_session_name: "pidash-dns-admin",
})

puts
puts r53_creds.inspect

Aws.config[:credentials] = Aws::Credentials.new(r53_creds.credentials.access_key_id,
                                                r53_creds.credentials.secret_access_key,
                                                r53_creds.credentials.session_token)

#create route 53 object
r53 = Aws::Route53::Client.new
resp = r53.list_hosted_zones

puts
puts resp.inspect

resp = r53.change_resource_record_sets({
  hosted_zone_id: "ZWV6X5OUOKQ5O",
  change_batch: {
    changes: [
      {
        action: "UPSERT",
        resource_record_set: {
          name: "dns-test.pidash.cornell.edu.",
          type: "A",
          ttl: 60,
          resource_records: [
            {
              value: "192.168.1.14",
            },
          ],
        },
      },
    ],
  },
})

puts
puts resp.inspect

resp = r53.list_resource_record_sets({
  hosted_zone_id: "ZWV6X5OUOKQ5O", # required
})

puts
resp.resource_record_sets.each do |record|
  puts "name: #{record.name}"
  puts "type: #{record.type}"
  puts "ttl: #{record.ttl}"
  puts "values:"

  record.resource_records.each do |value|
    puts "\t#{value.value}"
  end
  puts
end
