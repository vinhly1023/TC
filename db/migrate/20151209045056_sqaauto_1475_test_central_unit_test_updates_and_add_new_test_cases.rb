class Sqaauto1475TestCentralUnitTestUpdatesAndAddNewTestCases < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1475 Test Central: Unit test: Updates and add new test cases'
    connection = ActiveRecord::Base.connection

    connection.execute "INSERT INTO `cases` (`id`, `name`, `description`, `script_path`) VALUES (476,'TC functionality tests','Automated health check on Test Central\\\'s main functionality','controllers/tc_functionality_tests.rb');"
    connection.execute "INSERT INTO `suites` (`id`, `name`, `description`, `silo_id`, `order`) VALUES (68, 'Functionality Test', 'Test Central functionality test', 4, 4);"
    connection.execute 'INSERT INTO `case_suite_maps` (`id`, `suite_id`, `case_id`, `order`) VALUES (446, 68, 476, 1);'
  end

  def down
    say 'SQAAUTO-1475 Test Central: Unit test: Updates and add new test cases - rollback'
    connection = ActiveRecord::Base.connection
    connection.execute 'DELETE FROM `case_suite_maps` WHERE id=446;'
    connection.execute 'DELETE FROM `suites` WHERE id=68;'
    connection.execute 'DELETE FROM `cases` WHERE id=476;'
  end
end
