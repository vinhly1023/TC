class Sqaauto17541215ReleaseIncreaseCharactersNumberOfSkillColumnData < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1754 12/15 Release: CONTENT Automation: Database: Request to increase character number of SKILL column in database'
    say 'Set length of skill column of atg_moas table to 120'
    change_column('atg_moas', 'skills', :string, limit: 120, default: '', null: false)
  end
end
