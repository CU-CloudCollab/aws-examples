#!/usr/bin/env ruby

# Written as a script to start/stop ec2 instances based on tags
# Example Usage:
# Start all ec2 instances with envirnoment tag and value of development
#   ./ec2_start_stop.rb --r us-east-1 --t environment:development --op start

# Start all ec2 instances with envirnoment tag and value of development
#   ./ec2_start_stop.rb --t environment:development --op stop

require 'aws-sdk'
require 'optparse'

# Options
# -r = region, -t name:value, -op operation (start/stop)
OPTIONS = {}

#Default Values
OPTIONS[:region] = 'us-east-1'

OptionParser.new do |opt|
  opt.on('--r REGION') { |o| OPTIONS[:region] = o }
  opt.on('--t TAG NAME AND VALUE (TAG:VALUE)') { |o| OPTIONS[:tagname] = o }
  opt.on('--op OPERATION') { |o| OPTIONS[:operation] = o }
end.parse!

EC2 = Aws::EC2::Resource.new(:region=>OPTIONS[:region])

def GetInstances()
  values = OPTIONS[:tagname].to_s.split(':')
  return EC2.instances(filters: [{ name: 'tag:' + values[0].to_s, values:[values[1].to_s]}])
end

def DoWork(ec2list)
  ec2list.each do |i|
    if OPTIONS[:operation].to_s.upcase.eql?('START')
      i.start
    elsif OPTIONS[:operation].to_s.upcase.eql?('STOP')
      i.stop
    end
  end
end

DoWork(GetInstances())
