class Sqaauto1869EnhanceOutpostParameterDefinitionsToBeDefinedPerTestSuite < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1869 Enhance outpost parameter definitions to be defined per test suite'
    say 'Merge 2 columns \'available_test\' and \'parameters\' into one column \'run_parameters\''
    add_column :outposts, :parameters_url, :string, after: :exec_url
    add_column :outposts, :run_parameters, :text, limit: -1, after: :available_tests
    remove_column :outposts, :available_tests
    remove_column :outposts, :parameters
  end

  def down
    say 'SQAAUTO-1869 Enhance outpost parameter definitions to be defined per test suite'
    add_column :outposts, :available_tests, :text, limit: -1, after: :run_parameters
    add_column :outposts, :parameters, :text, limit: -1, after: :available_tests
    remove_column :outposts, :parameters_url
    remove_column :outposts, :run_parameters
  end
end
