$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'radical'
require 'screwcap'
require 'clockwork'
require 'radical/db'
require 'radical_daemon/screwcap_exts'
require 'radical_daemon/mail'

Thread.abort_on_exception = true

module Radical
  class Daemon 
    include Clockwork
  
    attr_accessor :task_manager, :threads

    def initialize(options = {})
      @task_manager = TaskManager.new(options)
      @threads = []
      unless @task_manager.respond_to?(:mail_from)
        @task_manager.mail_from = "Radical Daemon <do-not-reply@radical-daemon.com>"
      end
    end

    def run!(options = {})
      handler do |job|
        if $test_mode
          handle_job(job)
        else
          @threads << Thread.new(job) { |_job| handle_job(_job) }
        end
      end
  
      @task_manager.__tasks.each do |t|
        t.__build_commands(@task_manager.__command_sets)
        every(t.__options[:every], t.__name)
      end
  
      trap("INT") { $stdout << " Exiting...\n"; Kernel.exit(0) }
      do_run
    end

    def handle_job(job)
      out = @task_manager.run!(job).first
      if model = Job.find_by_name(job)
        if model.passed != out[:exit_code] and out[:exit_code] == 0 and @task_manager.mail_to
          RadicalMail.ok_message(@task_manager.mail_from, @task_manager.mail_to, job).deliver
        end
        model.update_attributes(:passed => out[:exit_code] == 0,
                                :stderr_output => out[:stderr],
                                :stdout_output => out[:stdout],
                                :last_checked_at => Time.now.utc)
      else
        Job.create(:passed => out[:exit_code] == 0,
                      :name => job,
                      :stderr_output => out[:stderr],
                      :stdout_output => out[:stdout],
                      :last_checked_at => Time.now.utc)
      end

      if out[:exit_code] != 0 and @task_manager.mail_to
        case out[:exit_code] 
        when 1
          RadicalMail.warning_message(@task_manager.mail_from, @task_manager.mail_to, job).deliver
        when 2
          RadicalMail.critical_message(@task_manager.mail_from, @task_manager.mail_to, job).deliver
        else
          RadicalMail.unknown_message(@task_manager.mail_from, @task_manager.mail_to, job).deliver
        end
      end
    end

    def do_run
      log "Starting clock for #{@@events.size} events: [ " + @@events.map { |e| e.to_s }.join(' ') + " ]"
      loop do
        tick
        break if $test_mode == true
        sleep 1
      end
      @threads.join
    end

  end
end
