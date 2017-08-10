#!/usr/bin/env ruby

# Convert an IAM secret access key into a SMTP password for use by SES SMTP.

require 'openssl'
require 'base64'
require 'net/smtp'
require 'optparse'

def aws_iam_smtp_password_generator(secret)
  message = "SendRawEmail"
  versionInBytes = "\x02"
  signatureInBytes = OpenSSL::HMAC.digest('sha256', secret, message)
  signatureAndVer = versionInBytes + signatureInBytes
  smtpPassword = Base64.encode64(signatureAndVer)
end

# parse out the command line options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Convert an IAM secret access key to an SES SMTP password. Optionaly send a test email, if access_key and sender_email are provided.'
              + 'Usage: iam-smtp-credentials.rb [options]'

  opts.on('--access_key ACCESS_KEY', 'This is the AWS API access key. Required only if you want to send a test email after the password conversion.') { |v| options[:access_key] = v }
  opts.on('--secret_access_key SECRET_ACCESS_KEY', 'REQUIRED. This is the AWS API secret access key to be converted to an SES SMTP password.') { |v| options[:secret_access_key] = v }
  opts.on('--sender_email EMAIL_ADDRESS', 'A sender email address that is already validated with SES. Required only if you want to send a test email after the password conversion.') { |v| options[:sender_email] = v }
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

#raise excpetion if there is a missing option
raise OptionParser::MissingArgument if options[:secret_access_key].nil?

smtp_password = aws_iam_smtp_password_generator(options[:secret_access_key])
puts "SES_SMTP_PASSWORD #{smtp_password}"

exit if options[:access_key].nil? || options[:sender_email].nil?

message = <<MESSAGE_END
From: <#{options[:sender_email]}>
To: <#{options[:sender_email]}>
Subject: SMTP e-mail test

This is a test e-mail message.
MESSAGE_END

smtp = Net::SMTP.new('email-smtp.us-east-1.amazonaws.com', 587)
smtp.enable_starttls_auto
smtp.start('localhost', options[:access_key], smtp_password)

smtp.send_message(message, options[:sender_email], options[:sender_email])
