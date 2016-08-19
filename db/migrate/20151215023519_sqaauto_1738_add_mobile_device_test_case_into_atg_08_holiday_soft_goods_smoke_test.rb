class Sqaauto1738AddMobileDeviceTestCaseIntoAtg08HolidaySoftGoodsSmokeTest < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1738 Add mobile device test case into \'ATG 08 - Holiday Soft Goods Smoke Test\''
    connection = ActiveRecord::Base.connection

    connection.execute "INSERT INTO `cases` (id, name, description, script_path) VALUES (478,'iPhone 6 English - Checkout with Account Balance','iPhone 6 English - Checkout with Account Balance','13_dv_soft_good_smoke_test/dvst05_ios_checkout_with_account_balance.rb');"
    connection.execute "INSERT INTO `cases` (id, name, description, script_path) VALUES (479,'(Android) Galaxy S4 English - Checkout with Account Balance','(Android) Galaxy S4 English - Checkout with Account Balance','13_dv_soft_good_smoke_test/dvst06_android_checkout_with_account_balance.rb');"
    connection.execute 'INSERT INTO `case_suite_maps` (id, suite_id, case_id, `order`) VALUES (448,56,478,448),(449,56,479,449);'
  end

  def down
    say 'SQAAUTO-1738 Add mobile device test case into \'ATG 08 - Holiday Soft Goods Smoke Test\''
    connection = ActiveRecord::Base.connection

    connection.execute 'DELETE FROM `cases` WHERE id IN (478,479);'
    connection.execute 'DELETE FROM `case_suite_maps` WHERE id IN (448,449);'
  end
end
