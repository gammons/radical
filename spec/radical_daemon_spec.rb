require 'spec_helper'

describe "The Radical Daemon" do
  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "ok\n"))
  end

  before(:each) do
    ActionMailer::Base.deliveries = []
    Job.delete_all
  end

  describe "The Recipe file" do
    describe "monitor" do
      it "should complain if it cant find the server" do
        tm = TaskManager.new
        tm.server :server, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"
        lambda { tm.monitor :unknown }.should raise_error(ArgumentError)

        tm = TaskManager.new
        tm.server :server, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"
        lambda { tm.monitor :server }.should_not raise_error(ArgumentError)
      end

      it "should complain if it cannot find people to alert" do
        tm = TaskManager.new
        tm.server :server, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"
        tm.sysop :bob, :email => "bob@bob.com"
        lambda { tm.monitor :server, :alert => [:unknowns] }.should raise_error(ArgumentError)

        tm = TaskManager.new
        tm.server :server, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"
        tm.sysop :bob, :email => "bob@bob.com"
        lambda { tm.monitor :server, :alert => [:bob] }.should_not raise_error(ArgumentError)

        tm = TaskManager.new
        tm.server :server, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"
        tm.sysop :bob, :email => "bob@bob.com"
        tm.sysop :bob2, :email => "bob@bob.com"
        tm.group :bobs, [:bob, :bob2]
        lambda { tm.monitor :server, :alert => [:bobs] }.should_not raise_error(ArgumentError)
      end

      it "should complain if it cant find the thing to check" do
        tm = TaskManager.new
        tm.server :server, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"
        lambda { tm.monitor(:server) { run :unknown_check } }.should raise_error(ArgumentError)

        tm = TaskManager.new
        tm.server :server, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"
        tm.check :check, "test"
        lambda { tm.monitor(:server) { run :check } }.should_not raise_error(ArgumentError)
      end

      describe "run commands" do
        it "should override :every if it was passed in" do
          tm = TaskManager.new
          tm.server :server, :address => "abc.com", :user => "root", :keys => "~/.ssh/my_key"
          tm.sysop :bob, :email => "bob@example.com"
          tm.sysop :jim, :email => "jim@example.com"
          tm.check :cmd1, "cmd1"
          tm.check :cmd2, "cmd1"
          tm.monitor :server, :alert => :bob, :with => :email, :every => 5.minutes do
            run :cmd1, :every => 2.minutes, :alert => :jim, :with => :sms
            run :cmd2
          end
          mon = tm.__monitors.first
          mon.__commands.first.should == {:with => [:sms], :every => 2.minutes, :command => :cmd1, :alert => [:jim]}
          mon.__commands.last.should == {:with => [:email], :every => 5.minutes, :command => :cmd2, :alert => [:bob]}
        end
      end
    end

    describe "notifiers" do
      it "should respond to notifier" do
        tm = TaskManager.new
        tm.notifier :twilio, :sid => "sid", :token => "token"
        tm.should have(1).__notifiers
        tm.__notifiers.first.class.should == Radical::Notifiers::Twilio
        tm.__notifiers.first.opts.should == {:token => "token", :sid => "sid"}
      end

      it "should complain if it does not know the sms provider" do
      end
    end
  end

  #it "should send warning emails" do
  #  daemon = Radical::Daemon.new(:recipe_file => File.expand_path(File.dirname(__FILE__)) + "/../test/simple_test.rb")
  #  daemon.task_manager.stubs(:run!).returns([{:exit_code => 1, :stderr => "nope"}])
  #  daemon.run!
  #  ActionMailer::Base.deliveries.size.should == 1
  #  ActionMailer::Base.deliveries.first.subject.should == "[Radical] task is WARNING"
  #end

  #it "should send an ok email only if the previous email was warning" do
  #  daemon = Radical::Daemon.new(:recipe_file => File.expand_path(File.dirname(__FILE__)) + "/../test/simple_test.rb")
  #  daemon.task_manager.stubs(:run!).returns([{:exit_code => 0, :stdout => "yup"}])
  #  daemon.run!
  #  job = Job.last
  #  job.passed.should == true
  #  job.stdout_output.should == "yup"
  #  job.last_checked_at.should_not be_nil

  #  ActionMailer::Base.deliveries.size.should == 0

  #  daemon.task_manager.stubs(:run!).returns([{:exit_code => 1, :stdout => "yup"}])
  #  daemon.run!
  #  Job.count.should == 1
  #  ActionMailer::Base.deliveries.size.should == 1
  #  ActionMailer::Base.deliveries.first.subject.should == "[Radical] task is WARNING"
  #  job = Job.last
  #  job.passed.should == false
  #  job.stdout_output.should == "yup"
  #  job.last_checked_at.should_not be_nil

  #  daemon.task_manager.stubs(:run!).returns([{:exit_code => 0, :stdout => "yup"}])
  #  daemon.run!
  #  ActionMailer::Base.deliveries.size.should == 2
  #  ActionMailer::Base.deliveries.last.subject.should == "[Radical] task is now OK"
  #  Job.count.should == 1
  #  job = Job.last
  #  job.passed.should == true
  #  job.stdout_output.should == "yup"
  #  job.last_checked_at.should_not be_nil
  #end

  #it "should send an ok email only if the previous email was critical" do
  #  daemon = Radical::Daemon.new(:recipe_file => File.expand_path(File.dirname(__FILE__)) + "/../test/simple_test.rb")
  #  daemon.task_manager.stubs(:run!).returns([{:exit_code => 0, :stdout => "yup"}])
  #  daemon.run!
  #  ActionMailer::Base.deliveries.size.should == 0

  #  daemon.task_manager.stubs(:run!).returns([{:exit_code => 2, :stdout => "yup"}])
  #  daemon.run!
  #  ActionMailer::Base.deliveries.size.should == 1
  #  ActionMailer::Base.deliveries.first.subject.should == "[Radical] task is now CRITICAL"
  #  Job.count.should == 1
  #  job = Job.last
  #  job.passed.should == false
  #  job.stdout_output.should == "yup"
  #  job.last_checked_at.should_not be_nil

  #  daemon.task_manager.stubs(:run!).returns([{:exit_code => 0, :stdout => "yup"}])
  #  daemon.run!
  #  ActionMailer::Base.deliveries.size.should == 2
  #  ActionMailer::Base.deliveries.last.subject.should == "[Radical] task is now OK"
  #end

  #it "should send an unknown message if the error code was not 0, 1, or 2" do
  #  daemon = Radical::Daemon.new(:recipe_file => File.expand_path(File.dirname(__FILE__)) + "/../test/simple_test.rb")
  #  daemon.task_manager.stubs(:run!).returns([{:exit_code => 100, :stdout => "yup"}])
  #  daemon.run!
  #  ActionMailer::Base.deliveries.size.should == 1
  #  ActionMailer::Base.deliveries.first.subject.should == "[Radical] task is now UNKNOWN"
  #end
end
