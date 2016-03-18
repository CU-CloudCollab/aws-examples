#!/usr/bin/env ruby
require 'aws-sdk'
require 'cucloud'

UBUNTU_PATCH_COMMAND = "apt-get update; apt-get -y upgrade; reboot"
AMAZON_PATCH_COMMAND = "yum update -y; reboot & disown "

def send_patch_command(patch_instances, command)
  ssm = Aws::SSM::Client.new({region: 'us-east-1'})

  resp = ssm.send_command({
    instance_ids: patch_instances, # required
    document_name: "AWS-RunShellScript", # required
    timeout_seconds: 600,
    comment: "Patch It!",
    parameters: {
      "commands" => [command],
    }
  })
  puts resp.inspect
end

ec2_utils = Cucloud::Ec2Utils.new

resp = ec2_utils.get_instances_by_tag("auto_patch", "1")

ubuntu_patch_instances = []
amazon_patch_instances = []

puts "finding machines to patch"

resp.reservations.each do |res|
  res.instances.each do |instance|
    print instance.instance_id
    instance.tags.each do |tag|
      if tag.key.eql?("os")
        if tag.value.eql?("ubuntu")
          print " ubuntu, will patch"
          ubuntu_patch_instances.push(instance.instance_id)
        elsif tag.value.eql?("ecs") or tag.value.eql?("amazon")
          print " amazon, will patch"
          amazon_patch_instances.push(instance.instance_id)
        end
        puts
      end
    end
  end
end

send_patch_command(ubuntu_patch_instances, UBUNTU_PATCH_COMMAND) if ubuntu_patch_instances.any?
send_patch_command(amazon_patch_instances, AMAZON_PATCH_COMMAND) if amazon_patch_instances.any?
