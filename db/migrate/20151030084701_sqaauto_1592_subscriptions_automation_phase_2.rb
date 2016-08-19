class Sqaauto1592SubscriptionsAutomationPhase2 < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1592 Subscriptions automation phase 2'
    @connection = ActiveRecord::Base.connection

    say "Add new Test Case into 'cases' table"
    @connection.execute "INSERT INTO `cases` VALUES (443,'Subscription content license validation with different states of account','Subscription content license validation with different states of account','9_Subscriptions/ts05_content_license_validation_diffirent_account_states.rb',NULL,NULL);"

    say "Add data into 'case_suite_map' table"
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (413,66,443,NULL,NULL,413);'
  end
end
