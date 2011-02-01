##################
# Settings
##################

set :scripts_dir, "/usr/local/nagios/libexec/"
set :mail_to, "gammons@gmail.com"
set :mail_from, "radical@radical.com"
notifier :twilio, :sid => "sid", :token => "token"

##################
# Servers
##################

server :qm, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"

##################
# People to alert
##################

sysop :bob, :email => "bob@example.com", :sms => "2158017554"
sysop :jim, :email => "jim@example.com"
group :admins, [:bob, :jim]

##################
# Checks
##################

monitor :qm, :every => 5.minutes, :alert => [:admins], :with => [:email, :sms] do
  run :haproxy_check, :every => 2.minutes, :alert => [:admins], :with => [:email]
  run :apache_check
end

##################
# Check Commmands
##################

check :haproxy_check, "#{scripts_dir}/haproxy_check.rb"
