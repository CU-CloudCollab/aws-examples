#!/usr/bin/env ruby

require 'rubygems'
require 'aws-sdk'
require 'csv'
require 'mysql'

START_MONTH = ENV['START_MONTH'].to_i || Time.now.month - 1
END_MONTH = ENV['END_MONTH'].to_i || Time.now.month - 1
YEAR = ENV['YEAR'] || Time.now.year

MYSQL_HOST = ENV['MYSQL_HOST']
MYSQL_USER = ENV['MYSQL_USER']
MYSQL_PASS = ENV['MYSQL_PASS']
MYSQL_DB = ENV['MYSQL_DB'] || "billing_detail"

S3_BUCKET = ENV['S3_BUCKET']

BILLING_DETAIL_INSERT = "INSERT INTO billing_detail (invoice_id, payer_account_id, linked_account_id, record_type, record_id, product_name, rate_id, subscription_id, pricing_plan_id, usage_type, operation, availability_zone, reserved_instance, item_description, usage_start_date, usage_end_date, usage_quantity, blended_rate, blended_cost, unblended_rate, unblended_cost, resource_id, cost_center) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

if START_MONTH > END_MONTH then
  puts "The starting month cannot be greate than end month"
  exit(1)
elsif START_MONTH > 12 || START_MONTH < 1
  puts "The starting month must be between 1 and 12"
  exit(1)
elsif END_MONTH > 12 || END_MONTH < 1
  puts "The ending month must be between 1 and 12"
  exit(1)
end

db = Mysql.connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
s3 = Aws::S3::Client.new(region: 'us-east-1')

i = START_MONTH

begin
  get_month = i < 10 ? "0#{i}" : i
  zip_file = "078742956215-aws-billing-detailed-line-items-with-resources-and-tags-#{YEAR}-#{get_month}.csv.zip"
  puts "processing #{get_month}"
  
  resp = s3.get_object(
    response_target: zip_file,
    bucket: S3_BUCKET,
    key: zip_file)
  
  puts `unzip #{zip_file}`
  puts "beginning to process CSV file"
  CSV.foreach(File.basename(zip_file, '.zip')) do |row|
    if (row[0] and row[1] and row[3]) and (not row[0].eql?("InvoiceID"))
      st = db.prepare(BILLING_DETAIL_INSERT)
      st.execute(row[0],row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8],row[9],row[10],row[11],row[12],row[13],row[14],row[15],
        row[16],row[17],row[18],row[19],row[20],row[21],row[22])
      st.close
    end
  end
  
  puts "remove the csv and zip files"
  `rm #{zip_file}`
  `rm #{File.basename(zip_file, '.zip')}`
  
  i += 1
end while i <= END_MONTH

puts "process complete"
db.close