class Sqaauto1660UpdateVideoAndJustForFunCatagoryToLearningVideoAndJustForFunVideo < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1660 CONTENT Automation: ATG cabo: Category checking: Incorrect expected for Category checking'
    @connection = ActiveRecord::Base.connection
    @connection.execute "UPDATE atg_cabo_filter_list SET name = 'Learning Video' WHERE name = 'Video' AND type = 'Category' AND locale IN ('us', 'ca', 'au', 'uk', 'ie', 'row')"
    @connection.execute "UPDATE atg_cabo_filter_list SET name = 'Just for Fun Video' WHERE name = 'Just for Fun' AND type = 'Category' AND locale IN ('us', 'ca', 'au', 'uk', 'ie', 'row')"
  end
end
