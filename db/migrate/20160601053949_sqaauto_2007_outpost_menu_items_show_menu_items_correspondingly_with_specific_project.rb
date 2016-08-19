class Sqaauto2007OutpostMenuItemsShowMenuItemsCorrespondinglyWithSpecificProject < ActiveRecord::Migration
  def up
    say 'SQAAUTO-2007 Outpost: menu items: show menu items correspondingly with specific project'
    add_column :outposts, :menu_link, :text, limit: -1, after: :status
  end

  def down
    say 'SQAAUTO-2007 Outpost: menu items: show menu items correspondingly with specific project'
    remove_column :outposts, :menu_link
  end
end
