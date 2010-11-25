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
    it "should be able to load" do
      daemon = Radical::Daemon.new(:recipe_file => File.expand_path(File.dirname(__FILE__)) + "/../test/test_radical.rb")
      daemon.task_manager.should_not be_nil
    end

    it "should respond to checks_for" do
      tm = TaskManager.new
      tm.server :server, :address => "abc.com", :user => "root", :keys => "mykey"
      tm.checks_for :server, :every => 5.minutes do
        run "test", :desc => "Test this", :every => 3.minutes
      end

      task = tm.__tasks.first
      task.__options[:every].should == 300
      task.__build_commands
      command = task.__commands.first
      command[:type].should == :remote
      command[:from].should == "task"
      command[:desc].should == "Test this"
      command[:command].should == "test"
      command[:every].should == 3.minutes
    end
  end

  it "should send warning emails" do
    daemon = Radical::Daemon.new(:recipe_file => File.expand_path(File.dirname(__FILE__)) + "/../test/simple_test.rb")
    daemon.task_manager.stubs(:run!).returns([{:exit_code => 1, :stderr => "nope"}])
    daemon.run!
    ActionMailer::Base.deliveries.size.should == 1
    ActionMailer::Base.deliveries.first.subject.should == "[Radical] task is WARNING"
  end

  it "should send an ok email only if the previous email was warning" do
    daemon = Radical::Daemon.new(:recipe_file => File.expand_path(File.dirname(__FILE__)) + "/../test/simple_test.rb")
    daemon.task_manager.stubs(:run!).returns([{:exit_code => 0, :stdout => "yup"}])
    daemon.run!
    job = Job.last
    job.passed.should == true
    job.stdout_output.should == "yup"
    job.last_checked_at.should_not be_nil

    ActionMailer::Base.deliveries.size.should == 0

    daemon.task_manager.stubs(:run!).returns([{:exit_code => 1, :stdout => "yup"}])
    daemon.run!
    Job.count.should == 1
    ActionMailer::Base.deliveries.size.should == 1
    ActionMailer::Base.deliveries.first.subject.should == "[Radical] task is WARNING"
    job = Job.last
    job.passed.should == false
    job.stdout_output.should == "yup"
    job.last_checked_at.should_not be_nil

    daemon.task_manager.stubs(:run!).returns([{:exit_code => 0, :stdout => "yup"}])
    daemon.run!
    ActionMailer::Base.deliveries.size.should == 2
    ActionMailer::Base.deliveries.last.subject.should == "[Radical] task is now OK"
    Job.count.should == 1
    job = Job.last
    job.passed.should == true
    job.stdout_output.should == "yup"
    job.last_checked_at.should_not be_nil
  end

  it "should send an ok email only if the previous email was critical" do
    daemon = Radical::Daemon.new(:recipe_file => File.expand_path(File.dirname(__FILE__)) + "/../test/simple_test.rb")
    daemon.task_manager.stubs(:run!).returns([{:exit_code => 0, :stdout => "yup"}])
    daemon.run!
    ActionMailer::Base.deliveries.size.should == 0

    daemon.task_manager.stubs(:run!).returns([{:exit_code => 2, :stdout => "yup"}])
    daemon.run!
    ActionMailer::Base.deliveries.size.should == 1
    ActionMailer::Base.deliveries.first.subject.should == "[Radical] task is now CRITICAL"
    Job.count.should == 1
    job = Job.last
    job.passed.should == false
    job.stdout_output.should == "yup"
    job.last_checked_at.should_not be_nil

    daemon.task_manager.stubs(:run!).returns([{:exit_code => 0, :stdout => "yup"}])
    daemon.run!
    ActionMailer::Base.deliveries.size.should == 2
    ActionMailer::Base.deliveries.last.subject.should == "[Radical] task is now OK"
  end
end
