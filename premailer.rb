#!/usr/bin/env ruby
# Simple command line tool for sending HTML mails processed with Premailer

require 'premailer'
require 'mail'
require 'bluecloth'
require 'inifile'
require 'trollop'

# Load configuration file
config = IniFile.load('premailer.ini')


# Overrule the default message options in the ini-file with command arguments
opts = Trollop::options do
  opt :to, "Send the mail to", :default => config['message']['to']
  opt :from, "Use the from mail address", :default => config['message']['from']
  opt :subject, "Add a subject to the mail", :default => config['message']['subject']
end


# Set the mail server options
options = { :address              => config['server']['address'],
            :port                 => config['server']['port'],
            :domain               => config['server']['domain'],
            :openssl_verify_mode  => config['server']['openssl_verify_mode'],
            :enable_starttls_auto => config['server']['enable_starttls_auto']
}


# Read the content file given as argument
if ARGV.length != 1
  puts "Please provide a single file as argument"
else
  content = File.read(ARGV[0])
end


# Apply the content to the template
# TODO: Extend this option to include more snippets like introduction, footer etc.
mail = File.read('template.html').gsub("%CONTENT%", content)
premailer = Premailer.new(mail, :warn_level => Premailer::Warnings::SAFE, :with_html_string => true)


# Send the mail with configured options
Mail.defaults do
  delivery_method :smtp, options
end

Mail.deliver do
       to opts[:to]
     from opts[:from]
  subject opts[:subject]

  html_part do
    content_type 'text/html; charset=UTF-8'
    body premailer.to_inline_css
  end

  text_part do
    content_type 'text/plain; charset=ISO-8859-1; format=flowed'
    body premailer.to_plain_text
  end
end
