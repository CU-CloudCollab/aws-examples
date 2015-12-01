#!/usr/bin/env ruby

require 'rubygems'
require 'aws-sdk'
require 'optparse'

HOSTED_ZONE_ARN = "arn:aws:route53:::"

# parse out the command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: search.rb [options]"

  opts.on('--name DNS NAME', 'This is the dns name of the hosted zone)') { |v| options[:name] = v }

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

#raise excpetion if there is a missing option
raise OptionParser::MissingArgument if options[:name].nil?

# create route 53 object
r53 = Aws::Route53::Client.new()

# create a hosted zone for the dns name
resp = r53.create_hosted_zone({
  name: options[:name], # required
  caller_reference: "Nonce+12322", # required
})

# Create a ticket to delegate control from on prem to CIT AWS account
message = "Pleas create a NS record for " + options[:name] + " with the following servers: "
resp.delegation_set.name_servers.each do |ns|
  message += ns + " "
end

`mail -s "DNS Request" srb55@cornell.edu<<EOM
  #{message}
EOM`

# read in policy template
file = File.open("hosted_zone_policy_tmpl", "rb")
policy = file.read

# substite the correct hosted zone id into the ploicy document
policy.gsub!("#HOSTED_ZONE_ARN#", HOSTED_ZONE_ARN + resp.hosted_zone.id[1..-1])

# Create a name for the new policy with the hosted zone id
policy_name = "admin-for-" + resp.hosted_zone.id[12..-1]

# create the IAM policy
iam = Aws::IAM::Client.new
resp = iam.create_policy({
  policy_name: policy_name,
  policy_document: policy,
})
