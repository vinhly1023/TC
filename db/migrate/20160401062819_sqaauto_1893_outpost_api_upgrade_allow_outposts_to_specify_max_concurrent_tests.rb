class Sqaauto1893OutpostApiUpgradeAllowOutpostsToSpecifyMaxConcurrentTests < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1893 Outpost API Upgrade: Allow outposts to specify max concurrent tests'
    add_column :outposts, :limit_running, :integer, limit: 1, after: :status
    add_column :outposts, :running_count, :integer, limit: 1, after: :limit_running
  end

  def down
    say 'SQAAUTO-1893 Outpost API Upgrade: Allow outposts to specify max concurrent tests'
    remove_column :outposts, :limit_running
    remove_column :outposts, :running_count
  end
end
