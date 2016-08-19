class Sqaauto1716AtgAddStarterFlowSmokeTestForBogotaToTheHolidaySmoketestSuite < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1716 ATG starter flow smoke test for Bogota to the Holiday Smoketest suite'
    @connection = ActiveRecord::Base.connection

    say "Add new Test Case into 'cases' table"
    @connection.execute "INSERT INTO `cases` VALUES (477,'Bogota - Starter flow smoke test','add starter flow smoke test for Bogota','8_atg_lfcom_smoke_test/atg_bogota_starter_flow_smoke_test.rb',NULL,NULL);"

    say "Add data into 'case_suite_map' table"
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (447,56,477,NULL,NULL,447);'
  end
end
