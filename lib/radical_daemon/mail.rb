ActionMailer::Base.prepend_view_path File.expand_path(File.dirname(__FILE__))
ActionMailer::Base.delivery_method = :sendmail unless ActionMailer::Base.delivery_method == :test
#ActionMailer::Base.logger = Logger.new(STDOUT)

class RadicalMail < ActionMailer::Base
  def warning_message(from, to, job)
    mail(:from => from, :to => to, :subject => "[Radical] #{job} is WARNING")
  end

  def critical_message(from, to, job)
    mail(:from => from, :to => to, :subject => "[Radical] #{job} is now CRITICAL")
  end

  def unknown_message(from, to, job)
    mail(:from => from, :to => to, :subject => "[Radical] #{job} is now UNKNOWN")
  end

  def ok_message(from, to, job)
    mail(:from => from, :to => to, :subject => "[Radical] #{job} is now OK")
  end
end
