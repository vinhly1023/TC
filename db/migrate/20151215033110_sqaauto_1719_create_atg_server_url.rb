class Sqaauto1719CreateAtgServerUrl < ActiveRecord::Migration
  def up
    create_table :atg_server_urls do |t|
      t.string   'env', limit: 10
      t.string   'url', limit: 255

      t.timestamps null: false
    end

    say 'SQAAUTO-1719 ATG - Holiday - add ATG server health check test case'
    @connection = ActiveRecord::Base.connection

    say "Add new Test Case into 'cases' table"
    @connection.execute "INSERT INTO `cases` VALUES (480,'ATG server health checks for indvidual com nodes','add ATG server health checks for indvidual com nodes','7_atg_heartbeat/atg_server_health_check.rb',NULL,NULL);"

    say "Add data into 'case_suite_map' table"
    @connection.execute 'INSERT INTO `case_suite_maps` VALUES (480,50,480,NULL,NULL,450);'
  end

  def down
    drop_table :atg_server_urls
  end
end
