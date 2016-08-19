class Sqaauto1794AllowOutpostsToDefineTestParametersPerTestCaseSuite < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1794 Allow outposts to define test parameters per test case/suite'
    say 'Add Parameters column into Outposts table'
    add_column :outposts, :parameters, :text, limit: -1, after: :available_tests
  end

  def down
    say 'SQAAUTO-1794 Allow outposts to define test parameters per test case/suite'
    say 'Remove Parameters column from Outposts table'
    remove_column :outposts, :parameters
  end
end
