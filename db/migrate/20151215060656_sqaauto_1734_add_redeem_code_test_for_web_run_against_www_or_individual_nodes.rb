class Sqaauto1734AddRedeemCodeTestForWebRunAgainstWwwOrIndividualNodes < ActiveRecord::Migration
  def up
    say 'SQAAUTO_1734: ATG - Add redeem code test for Web - run against www or individual nodes'

    say 'SQAAUTO_1747: Implement new function: ATG import Promos file'
    create_table :atg_promotions do |t|
      t.string   'env',          limit: 10
      t.string   'promo_name',   limit: 50
      t.string   'num_prods',    limit: 5
      t.string   'prod_ids',     limit: 255
      t.timestamps               null: false
    end

    say 'SQAAUTO-1748: Add new \'Web - Check out with account Balance\' test case'
    @connection = ActiveRecord::Base.connection
    @connection.execute "INSERT INTO `cases` VALUES (482,'Web - Test Promotion - (Requires upload of Promo file) ','Web - Test Promotion - (Requires upload of Promo file) ','6_soft_good_smoke_test/dst36_web_test_promotion.rb',NULL,NULL);"
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (453,48,482,NULL,NULL,453),(454,56,482,NULL,NULL,454);'
  end

  def down
    drop_table :atg_promotions
  end
end
