  class TaskManager
  
    def checks_for(server, options = {}, &block)
      t = Task.new(options.merge({:name => "task", :server => server}), &block)
      t.clone_from(self)
      t.validate(self.__servers) unless options[:local] == true
      self.__tasks << t
    end
  end
