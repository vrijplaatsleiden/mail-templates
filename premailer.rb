#!/usr/bin/env ruby
# Simple command line tool for sending HTML mails processed with Premailer

require 'premailer'
require 'mail'
require 'bluecloth'
require 'inifile'
require 'trollop'

# Load configuration file
# TODO: Add an option to overrule the default ini-file.
# TODO: Check if ini-file exists
config = IniFile.load('premailer.ini')


# Overrule the default message options in the ini-file with command arguments
opts = Trollop::options do
  opt :to, "Address to send the mail to", :type => :string, :default => config['message']['to']
  opt :from, "Address to send the mail from", :type => :string, :default => config['message']['from']
  opt :subject, "Subject of the mail", :type => :string, :default => config['message']['subject']
  opt :title, "Title to use in the mail (default: same as subject)", :type => :string
  opt :template, "Master template file to use", :type => :string, :default => config['message']['template']
  opt :content, "Content file to use", :type => :string, :default => config['message']['content']
  opt :header, "Optional header file to use", :type => :string, :default => config['message']['header']
  opt :footer, "Optional footer file to use", :type => :string, :default => config['message']['footer']
  opt :unsubscribe, "Optional unsubscribe file to use", :type => :string, :default => config['message']['unsubscribe']
end

# Check if specified files actually exist
unless File.file?(opts[:template])
  puts "The template file you specified doesn't exist."
  exit
end

unless File.file?(opts[:content])
  puts "The content file you specified doesn't exist."
  exit
end

if opts[:header]
  unless File.file?(opts[:header])
    puts "The header file you specified doesn't exist."
    exit
  end
end

if opts[:footer]
  unless File.file?(opts[:footer])
    puts "The footer file you specified doesn't exist."
    exit
  end
end

if opts[:unsubscribe]
  unless File.file?(opts[:unsubscribe])
    puts "The unsubscribe file you specified doesn't exist."
    exit
  end
end


# Set the mail server options
options = { :address              => config['server']['address'],
            :port                 => config['server']['port'],
            :domain               => config['server']['domain'],
            :openssl_verify_mode  => config['server']['openssl_verify_mode'],
            :enable_starttls_auto => config['server']['enable_starttls_auto']
}

## Apply the snippets and content to the template
mail = File.read(opts[:template])

# Add title based on argument, ini-file or, when both are lacking, the subject
if opts[:title]
  mail = mail.gsub("<!-- TITLE -->", opts[:title])
else
  mail = mail.gsub("<!-- TITLE -->", opts[:subject])
end

# Add header
if opts[:header]
  mail = mail.gsub("<!-- HEADER -->", File.read(opts[:header]))
end

# Add footer
if opts[:footer]
  mail = mail.gsub("<!-- FOOTER -->", File.read(opts[:footer]))
end

# Add footer
if opts[:unsubscribe]
  mail = mail.gsub("<!-- UNSUBSCRIBE -->", File.read(opts[:unsubscribe]))
end

# And always add content
mail = mail.gsub("<!-- CONTENT -->", File.read(opts[:content]))

premailer = Premailer.new(mail, :warn_level => Premailer::Warnings::SAFE, :with_html_string => true)


## Send the mail with configured options
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
