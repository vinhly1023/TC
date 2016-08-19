class Sqaauto1594SubscriptionAutomationPhase4 < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1594 Aubscriptions add new test case to check webservices of subscriptions'
    @connection = ActiveRecord::Base.connection

    say "Add new Test Case into 'cases' table"
    @connection.execute "INSERT INTO `cases` VALUES (441,'Cancel and restart membership','add cancel and restart membership','9_Subscriptions/ts03_cancel_and_restart_membership.rb',NULL,NULL), (442,'Subscriptions license validation with cancelled, active and active cancelled state','subscriptions license validation with cancelled active and active cancelled state','9_Subscriptions/ts04_subscriptions_license_validation_with_cancelled_active_and_active_cancelled_state.rb',NULL,NULL);"

    say "Add data into 'case_suite_map' table"
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (411,66,441,NULL,NULL,411), (412,66,442,NULL,NULL,412);'
  end
end
