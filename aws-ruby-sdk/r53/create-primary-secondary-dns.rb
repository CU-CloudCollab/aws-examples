#!/usr/bin/env ruby

require 'rubygems'
require 'aws-sdk'

DNS_NAME = "test.example.com."  # DNS Entry to Update
ZONE_ID = "Z1Z1Z1Z1Z1Z1"        # DNS Zone ID, Found in route53 under hosted zones
PRIMARY_IP = "192.168.0.1"      # Primary IP
SECONDARY_IP = "192.168.0.2"    # Secondary IP

#create route 53 object
r53 = AWS::Route53.new

# Grab all the recordsets
rrsets = AWS::Route53::HostedZone.new(ZONE_ID).rrsets

# loop through the recordsets deleting any that match our domain name
rrsets.each do |rset|
  if rset.name.eql?(DNS_NAME)
    puts "Found it"
    rset.delete
  end
end

# In order to use failover DNS first we have to create a health check
# this is a simple http health check that will ping the primary ip on 
# port 80
resp = r53.client.create_health_check(caller_reference: "HTTP-#{PRIMARY_IP}", health_check_config: {ip_address: PRIMARY_IP, type: "HTTP"})

#Create a new batch update
batch = AWS::Route53::ChangeBatch.new(ZONE_ID)

# Add the pmirary IP to the DNS batch, refrencing the health check
# we created earlier
batch << AWS::Route53::CreateRequest.new(DNS_NAME, 'A', 
  ttl: 60, 
  failover: "PRIMARY", 
  set_identifier: "test-primary", 
  health_check_id: resp.health_check.id,
  resource_records: [{value: PRIMARY_IP }])

# add the secondary ip to the DNS batch  
batch << AWS::Route53::CreateRequest.new(DNS_NAME, 'A', 
  ttl: 60, 
  failover: "SECONDARY", 
  set_identifier: "test-secondary", 
  resource_records: [{value: SECONDARY_IP }])

# run the batch update  
change_info = batch.call


