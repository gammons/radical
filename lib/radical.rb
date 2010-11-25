%w(sqlite3 active_record action_mailer).each {|l| require l }

module Radical
  VERSION="0.1.0"
end
