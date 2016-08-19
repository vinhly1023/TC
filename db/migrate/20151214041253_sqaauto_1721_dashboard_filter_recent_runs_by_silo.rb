class Sqaauto1721DashboardFilterRecentRunsBySilo < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1721: Dashboard: Filter recent runs by Silo'
    say 'Remove EP from silos table'

    @connection = ActiveRecord::Base.connection
    @connection.execute "DELETE FROM silos where name='EP';"
  end
end
