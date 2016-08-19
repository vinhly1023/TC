class Sqaauto1636ShowTestCentralCurrentVersionSomewhereOnTheUi < ActiveRecord::Migration
  def up
	say 'SQAAUTO-1636: Show Test Central current version somewhere on the UI'
	say 'Add version column into stations table'
	add_column :stations, :version, :string
  end
  
  def down
	say 'SQAAUTO-1636: Show Test Central current version somewhere on the UI'
	say 'Remove version column from stations table'
	remove_column :stations, :version, :string
  end
end
