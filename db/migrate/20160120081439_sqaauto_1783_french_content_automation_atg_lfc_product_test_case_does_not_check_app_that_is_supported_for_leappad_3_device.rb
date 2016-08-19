class Sqaauto1783FrenchContentAutomationAtgLfcProductTestCaseDoesNotCheckAppThatIsSupportedForLeappad3Device < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1783: French CONTENT Automation: ATG LFC: Product: Test case does not check app that is supported for LeapPad 3 device'
    @connection = ActiveRecord::Base.connection
    @connection.execute "UPDATE `atg_moas_fr_mapping` SET field_name = french, french = english, english = field_name, field_name = 'platform' WHERE field_name = 'platform';"
  end
end
