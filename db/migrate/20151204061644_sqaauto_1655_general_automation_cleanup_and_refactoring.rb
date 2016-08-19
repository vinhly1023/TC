class Sqaauto1655GeneralAutomationCleanupAndRefactoring < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1655 General automation cleanup and refactoring'
    @connection = ActiveRecord::Base.connection

    say 'Update data atg_configurations table'
    @connection.execute 'DELETE FROM `atg_configurations`'
    @connection.execute 'INSERT INTO `atg_configurations` (id, data) VALUES (\'1\', \'{"vin_acc": {"vin_password": "M6v1X5o", "vin_username": "leapfrog_admin"}, "ac_account": {"empty_acc": ["pm201409090848057us@leapfrog.test", "123456"], "credit_acc": ["ltrc_atg_uat_us_612201410531@sharklasers.com", "123456"], "balance_acc": ["pm201409090910038us@leapfrog.test", "123456"], "credit_balance_acc": ["pm201409090840046us@leapfrog.test", "123456"]}, "catalog_entry": {"ce_sku": "58997-96914", "ce_sale": "", "prod_id": "prod58997-96914", "ce_price": "$7.50", "ce_strike": "", "ce_pdp_type": "Learning Game", "ce_pdp_title": "PAW Patrol: PAWsome Adventures!", "ce_cart_title": "PAW Patrol: PAWsome Adventures!", "ce_product_type": "Digital Download", "ce_catalog_title": "PAW Patrol: PAWsome Adventures!"}, "paypal_account": {"p_au_acc": ["hantr6_1352969230_per@yahoo.com", "12345678"], "p_ca_acc": ["hant11_1352975031_per@yahoo.com", "12345678"], "p_ie_acc": ["hantr5_1352968322_per@yahoo.com", "12345678"], "p_uk_acc": ["hantr5_1352968322_per@yahoo.com", "12345678"], "p_us_acc": ["hantr1_1352963954_per@yahoo.com", "352965367"], "p_row_acc": ["hantr7_1352969911_per@yahoo.com", "12345678"]}, "leapfrog_account": {"dev_acc": "ltrc_dev_test@leapfrog.test/123456", "uat_acc": "ltrc_uat_test@leapfrog.test/123456", "dev2_acc": "ltrc_dev2_test@leapfrog.test/123456", "prod_acc": "ltrc_prod_test@leapfrog.test/123456", "uat2_acc": "ltrc_uat2_test@leapfrog.test/123456", "preview_acc": "ltrc_preview_test@leapfrog.test/123456", "staging_acc": "ltrc_staging_test@leapfrog.test/123456"}}\');'

    say 'Rename test case folder'
    @connection.execute "UPDATE cases SET script_path = '7_atg_heartbeat/atg_heartbeat_checking.rb' WHERE id = 319"
    @connection.execute "UPDATE cases SET script_path = '8_atg_lfcom_smoke_test/atg_lfcom_smoke_test.rb' WHERE id = 321"
  end
end
