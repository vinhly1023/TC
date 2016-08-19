class Sqaauto1733AtgAddWebCheckoutWithAccountBalanceThatCanBeRunAgainstIndividualComServers < ActiveRecord::Migration
  def up
    say 'SQAAUTO_1733: ATG - Add Web - checkout with account balance - (redeem code at checkout) that can be run against individual com servers'

    say 'SQAAUTO-1743: Add new \'Web - Check out with account Balance\' test case'
    @connection = ActiveRecord::Base.connection
    @connection.execute "INSERT INTO `cases` VALUES (481,'Web - Checkout with Account Balance','Web - Checkout with Account Balance','6_soft_good_smoke_test/dst35_web_check_out_with_account_balance.rb',NULL,NULL);"
    @connection.execute 'UPDATE `case_suite_maps` SET id = 450 WHERE id = 480'
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (451,48,481,NULL,NULL,451),(452,56,481,NULL,NULL,452);'

    say 'SQAAUTO-1744: Create atg_com_servers table'
    create_table :atg_com_servers do |t|
      t.string   'env',        limit: 10
      t.string   'hostname',   limit: 255
      t.timestamps null: false
    end
  end

  def down
    drop_table :atg_com_servers
  end
end
