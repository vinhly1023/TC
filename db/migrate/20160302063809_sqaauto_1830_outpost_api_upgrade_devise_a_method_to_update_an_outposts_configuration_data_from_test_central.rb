class Sqaauto1830OutpostApiUpgradeDeviseAMethodToUpdateAnOutpostsConfigurationDataFromTestCentral < ActiveRecord::Migration
  def up
    say "SQAAUTO-1830: Outpost API upgrade: Devise a method to update an outpost's configuration data from Test Central"
    add_column :outposts, :outpost_apis, :text, limit: -1, after: :status
    remove_column :outposts, :status_url
    remove_column :outposts, :exec_url
    remove_column :outposts, :parameters_url
  end

  def down
    say "SQAAUTO-1830: Outpost API upgrade: Devise a method to update an outpost's configuration data from Test Central"
    add_column :outposts, :status_url, :string, after: :status
    add_column :outposts, :exec_url, :string, after: :status_url
    add_column :outposts, :parameters_url, :string, after: :exec_url
    remove_column :outposts, :outpost_apis
  end
end
