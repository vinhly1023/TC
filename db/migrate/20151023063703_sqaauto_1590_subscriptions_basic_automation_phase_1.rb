class Sqaauto1590SubscriptionsBasicAutomationPhase1 < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1590 Create Subscriptions Test Suite'
    @connection = ActiveRecord::Base.connection

    say "Add new Test Suite into 'suites' table"
    @connection.execute "INSERT INTO `suites` VALUES (66,'Subscriptions','Subscriptions test suite',1,NULL, NULL, 33);"

    say "Add new Test Case into 'cases' table"
    @connection.execute "INSERT INTO `cases` VALUES (439,'Download subscriptions content app','add download subscriptions content app script','9_Subscriptions/ts01_download_subscriptions_content_app.rb',NULL,NULL),(440,'Purchase app with subscriptions account','add purchase app with subscriptions account script','9_Subscriptions/ts02_purchase_app_with_subscriptions_account.rb',NULL,NULL);"

    say "Add data into 'case_suite_map' table"
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (409,66,439,NULL,NULL,409),(410,66,440,NULL,NULL,410);'
  end
end
