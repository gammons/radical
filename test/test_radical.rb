server :qm, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"

set :scripts_dir, "/usr/local/nagios/libexec/"
set :mail_to, "gammons@gmail.com"
set :mail_from, "radical@radical.com"

checks_for :qm, :every => 5.minutes do
  run "#{scripts_dir}/haproxy_check.rb", :desc => "Ensure haproxy is running"
  run "#{scripts_dir}/address_check.rb", :desc => "Check address parser"
end
