#!/usr/bin/env ruby

require 'aws-sdk'

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: "training")
})

@ec2  = Aws::EC2::Client.new
egress_port_pairs =[[80,80], [443,443], [22,22], [1024, 65535]]
inress_port_pairs =[[80,80], [443,443], [22,22], [1024, 65535]]

def create_allow_entries(acl_id, egress, port_pairs, protocol= "6", cidr_block = "0.0.0.0/0")

  port_pairs.each do |port_pair|
    @rule_number += 100
    resp = @ec2.create_network_acl_entry({
      network_acl_id: acl_id,
      rule_number: @rule_number,
      protocol: protocol,
      rule_action: "allow",
      egress: egress,
      cidr_block: cidr_block,
      port_range: {
        from: port_pair[0],
        to: port_pair[1]
      },
    })
  end
end

regions = @ec2.describe_regions({})

regions.regions.each do |region|
  puts region.region_name
  Aws.config[:region] = region.region_name
  @ec2 = Aws::EC2::Client.new

  nacls = @ec2.describe_network_acls({})

  nacls.network_acls.each do |acl|
    #Find default ACL
    if acl.is_default
      #Find all current entries and delete them
      acl.entries.each do |entry|
        if entry.rule_number < 32767
          resp = @ec2.delete_network_acl_entry({
            network_acl_id: acl.network_acl_id,
            rule_number: entry.rule_number,
            egress: entry.egress,
          })
        end
      end

      # crete basic port mappings
      [true, false].each do |egress|
        @rule_number = 0
        create_allow_entries(acl.network_acl_id, egress, egress_port_pairs)

        # create rules for cornell networks
        create_allow_entries(acl.network_acl_id, egress, [[-1,-1]], "-1", cidr_block= "10.0.0.0/8")
        create_allow_entries(acl.network_acl_id, egress, [[-1,-1]], "-1", cidr_block= "128.84.0.0/16")
        create_allow_entries(acl.network_acl_id, egress, [[-1,-1]], "-1", cidr_block= "128.253.0.0/16")
        create_allow_entries(acl.network_acl_id, egress, [[-1,-1]], "-1", cidr_block= "132.236.0.0/16")
      end
    end
  end
end
