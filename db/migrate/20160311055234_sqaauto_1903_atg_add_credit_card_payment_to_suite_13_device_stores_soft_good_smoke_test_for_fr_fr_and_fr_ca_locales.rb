class Sqaauto1903AtgAddCreditCardPaymentToSuite13DeviceStoresSoftGoodSmokeTestForFrFrAndFrCaLocales < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1903: ATG - Add Credit Card payment to suite # 13 - Device Stores - Soft Good Smoke Test for FR-FR and FR-CA locale'
    @connection = ActiveRecord::Base.connection
    @connection.execute 'DELETE FROM `atg_address`'
    @connection.execute "INSERT INTO `atg_address` VALUES (1,'US','217 2nd St',NULL,'Juneau','AK','99801-1267','0123456789'),(2,'CA','6693 Concession 1, Puslinch',NULL,'Wellington','ON','M0B 2J0','0123456789'),(3,'UK','6, Stanhope Road',NULL,'Bedford','BEDS','MK41 8BU','0123456789'),(4,'AU','4 Durham Rd Cooee',NULL,'Burnie','TAS','7320','0123456789'),(5,'FR_FR','47 Rue des Couronnes',NULL,'Paris',NULL,'75020','0123456789'),(6,'FR_CA','945 Chemin de Chambly',NULL,'Longueuil','AB','J4H 4A9','0123456789');"
  end

  def down
    say 'SQAAUTO-1903: ATG - Add Credit Card payment to suite # 13 - Device Stores - Soft Good Smoke Test for FR-FR and FR-CA locale'
    @connection = ActiveRecord::Base.connection
    @connection.execute 'DELETE FROM `atg_address`'
    @connection.execute "INSERT INTO `atg_address` VALUES (1,'US','217 2nd St',NULL,'Juneau','AK','99801-1267','0123456789'),(2,'CA','6693 Concession 1, Puslinch',NULL,'Wellington','ON','M0B 2J0','0123456789'),(3,'UK','6, Stanhope Road',NULL,'Bedford','BEDS','MK41 8BU','0123456789'),(4,'AU','4 Durham Rd Cooee',NULL,'Burnie','TAS','7320','0123456789');"
  end
end
