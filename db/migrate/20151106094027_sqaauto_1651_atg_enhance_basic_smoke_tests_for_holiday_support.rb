class Sqaauto1651AtgEnhanceBasicSmokeTestsForHolidaySupport < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1651 ATG: Enhance basic smoke tests for holiday support'
    @connection = ActiveRecord::Base.connection

    say 'Delete Purchase Flow - Account Balance and Saved CC (Digital Web) from Holiday Soft Good Smoke Test'
    @connection.execute 'DELETE FROM case_suite_maps WHERE suite_id = 56 and case_id = 412;'

    say 'Add new Narnia, Bogota and LFC English Account Balance check out test cases'
    @connection.execute "INSERT INTO `cases` VALUES (444,'Narnia - Check out with account Balance','Narnia - Check out with account Balance','13_dv_soft_good_smoke_test/dvst02_narnia_checkout_with_account_balance.rb',NULL,NULL),(445,'Bogota - Check out with Account Balance','Bogota - Check out with Account Balance','13_dv_soft_good_smoke_test/dvst03_bogota_checkout_with_account_balance.rb',NULL,NULL),(446,'LFC English - Check out with account Balance','LFC English - Check out with account Balance','13_dv_soft_good_smoke_test/dvst04_lfc_en_checkout_with_account_balance.rb',NULL,NULL);"
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (414,56,444,NULL,NULL,414),(415,56,445,NULL,NULL,415),(416,56,446,NULL,NULL,416);'
  end
end
