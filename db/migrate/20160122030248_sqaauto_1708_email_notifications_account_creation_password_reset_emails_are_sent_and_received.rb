class Sqaauto1708EmailNotificationsAccountCreationPasswordResetEmailsAreSentAndReceived < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1708 Email notifications: test that account creation, password reset emails are sent and received'
    @connection = ActiveRecord::Base.connection

    say "Add new Test Case into 'cases' table"
    @connection.execute "INSERT INTO `cases` VALUES (483,'Email notifications checking','Email notifications: test that account creation, password reset emails are sent and received','2_SmokeTest/ts23_email_notification_checking.rb',NULL,NULL);"

    say "Add data into 'case_suite_map' table"
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (455,24,483,NULL,NULL,455);'
  end
end
