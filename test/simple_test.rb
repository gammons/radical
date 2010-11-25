server :qm, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"

set :mail_to, "gammons@gmail.com"

checks_for :qm, :every => 5.minutes do
  run "test"
  run "test"
end
