class TaskManager

  def monitor(server, options = {}, &nlock)
    # I am here.
  end

  def checks_for(server, options = {}, &block)
    t = Task.new(options.merge({:name => "task", :server => server}), &block)
    t.clone_from(self)
    t.validate(self.__servers) unless options[:local] == true
    self.__tasks << t
  end

  def twilio(sid, token)
    self.__twilio_sid = sid
    self.__twilio_token =  token
  end

  def sysop(name, hsh)
    self.__sysops ||= []
    self.__sysops << hsh.merge(:name => name)
  end

  def group(name, members)
    self.__groups ||= []
    self.__groups << {:name => name, :members => members}
  end
end
