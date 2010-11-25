db_file = File.expand_path(File.dirname(__FILE__) + "/../../db/radical.db")
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => db_file)

if ActiveRecord::Base.connection.select_value("select count(*) from sqlite_master where name='jobs'") == 0
  class AddJobsTable < ActiveRecord::Migration
    create_table(:jobs, :force => true) do |t|
      t.string :name
      t.boolean :passed
      t.string :stderr_output
      t.string :stdout_output
      t.datetime :last_checked_at
    end
  end
end

class Job < ActiveRecord::Base; end
