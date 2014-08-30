#!/usr/bin/env ruby
# Simple command line tool for sending HTML mails processed with Premailer

require 'premailer'
require 'mail'
require 'bluecloth'
require 'inifile'
require 'trollop'

# Load configuration file
# TODO: Add an option to overrule the default ini-file.
config = IniFile.load('premailer.ini')


# Overrule the default message options in the ini-file with command arguments
# TODO: Add a content snippet option, possibly including multiple snippets
opts = Trollop::options do
  opt :to, "Address to send the mail to", :default => config['message']['to']
  opt :from, "Address to send the mail from", :default => config['message']['from']
  opt :subject, "Subject of the mail", :default => config['message']['subject']
  opt :template, "Template file to use", :default => config['message']['template']
  opt :content, "Content file to use", :default => config['message']['content']
end


# Set the mail server options
options = { :address              => config['server']['address'],
            :port                 => config['server']['port'],
            :domain               => config['server']['domain'],
            :openssl_verify_mode  => config['server']['openssl_verify_mode'],
            :enable_starttls_auto => config['server']['enable_starttls_auto']
}


# Apply the content to the template
# TODO: Extend this option to include more snippets like introduction, footer etc.
mail = File.read('template.html').gsub("%CONTENT%", File.read(opts[:content]))
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
