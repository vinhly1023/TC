class Sqaauto1789AtgAddLocalesToSuite7SoftGoodSmokeTest < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1789 ATG - Add locales to suite # 7- Soft Good Smoke Test'
    @connection = ActiveRecord::Base.connection

    say 'Update Test case name'
    @connection.execute "UPDATE `cases` SET name = 'Create Account - Email is existed in WEBCRM as REGISTERED', description = 'Create Account - Email is existed in WEBCRM as REGISTERED' WHERE id = 387"
    @connection.execute "UPDATE `cases` SET name = 'Purchase Flow - Credit Card - Registered User - Expired CC tied to account', description = 'Purchase Flow - Credit Card - Registered User - Expired CC tied to account' WHERE id = 416"

    say 'Update ATG Address data'
    @connection.execute 'DELETE FROM `atg_address`'
    @connection.execute "INSERT INTO `atg_address` VALUES (1,'US','217 2nd St',NULL,'Juneau','AK','99801-1267','0123456789'),(2,'CA','6693 Concession 1, Puslinch',NULL,'Wellington','ON','M0B 2J0','0123456789'),(3,'UK','6, Stanhope Road',NULL,'Bedford','BEDS','MK41 8BU','0123456789'),(4,'AU','4 Durham Rd Cooee',NULL,'Burnie','TAS','7320','0123456789');"

    say 'Update ATG Credit Card data'
    @connection.execute 'DELETE FROM `atg_credit`'
    @connection.execute "INSERT INTO `atg_credit` VALUES (1,'Visa','4336652085322654');"
  end
end
