class Sqaauto1730RequestToTestInAppBundlesCategoryPage < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1730 Request to test in App Bundles category page'
    @connection = ActiveRecord::Base.connection

    say "Add data into 'atg_filter_list' table"
    @connection.execute <<-SQL_STRING.strip_heredoc
      INSERT INTO `atg_filter_list`
      VALUES (484,'us','App Bundle','/en-us/app-center/c/_/N-1z141it','Category'),
        (485,'ca','App Bundle','/en-ca/app-center/c/_/N-1z141it','Category'),
        (486,'uk','App Bundle','/en-gb/app-centre/c/_/N-1z141it','Category'),
        (487,'au','App Bundle','/en-au/app-centre/c/_/N-1z141it','Category'),
        (488,'ie','App Bundle','/en-ie/app-centre/c/_/N-1z141it','Category'),
        (489,'row','App Bundle','/en-oe/app-center/c/_/N-1z141it','Category');
    SQL_STRING
  end
end
