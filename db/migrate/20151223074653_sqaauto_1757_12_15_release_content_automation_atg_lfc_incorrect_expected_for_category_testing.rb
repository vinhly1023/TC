class Sqaauto17571215ReleaseContentAutomationAtgLfcIncorrectExpectedForCategoryTesting < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1757 CONTENT Automation_ATG LFC_Incorrect expected for Category testing'
    @connection = ActiveRecord::Base.connection

    say "Delete data into 'atg_lfc_filter_list' table with condition App Bundles"
    @connection.execute 'DELETE FROM atg_lfc_filter_list WHERE name = \'App Bundles\';'

    say "Add data into 'atg_lfc_filter_list' table"
    @connection.execute <<-SQL_STRING.strip_heredoc
      INSERT INTO `atg_lfc_filter_list`
      VALUES (86,'us','App Bundle','/en-us/app-center-lfc/c/_/N-1z141it','Category'),
        (170,'ca','App Bundle','/en-ca/app-center-lfc/c/_/N-1z141it','Category'),
        (251,'uk','App Bundle','/en-gb/app-centre-lfc/c/_/N-1z141it','Category'),
        (333,'au','App Bundle','/en-au/app-centre-lfc/c/_/N-1z141it','Category'),
        (414,'ie','App Bundle','/en-ie/app-centre-lfc/c/_/N-1z141it','Category'),
        (483,'row','App Bundle','/en-oe/app-center-lfc/c/_/N-1z141it','Category');
    SQL_STRING

    say "Change the FR Category 'e-Livres' to 'e-Livre'"
    @connection.execute "UPDATE `atg_lfc_filter_list` SET name = 'e-Livre' WHERE type = 'Category' AND name = 'e-Livres';"

    say "Change the FR Category 'Jeux éducatifs' to 'Jeu éducatif'"
    @connection.execute "UPDATE `atg_lfc_filter_list` SET name = 'Jeu éducatif' WHERE type = 'Category' AND name = 'Jeux éducatifs';"

    say "Change the FR Category 'Vidéos éducatives' to 'Vidéo éducative'"
    @connection.execute "UPDATE `atg_lfc_filter_list` SET name = 'Vidéo éducative' WHERE type = 'Category' AND name = 'Vidéos éducatives';"

    say "Change the FR Category 'Livres interactifs' to 'Livre interactif'"
    @connection.execute "UPDATE `atg_lfc_filter_list` SET name = 'Livre interactif' WHERE type = 'Category' AND name = 'Livres interactifs';"

    say "Change the FR Category 'Vidéos pour s'amuser' to 'Vidéo pour s'amuser'"
    @connection.execute "UPDATE `atg_lfc_filter_list` SET name = 'Vidéo pour s\\\'amuser' WHERE type = 'Category' AND name = 'Vidéos pour s\\\'amuser';"
  end
end
