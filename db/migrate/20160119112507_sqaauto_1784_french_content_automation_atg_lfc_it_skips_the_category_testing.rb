class Sqaauto1784FrenchContentAutomationAtgLfcItSkipsTheCategoryTesting < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1784 french content automation: atg lfc: it skips the category testing'
    @connection = ActiveRecord::Base.connection

    say "Change the FR category and contenttype 'e-Livres' to 'e-Livre'"
    @connection.execute "UPDATE `atg_moas_fr_mapping` SET french = 'e-Livre' WHERE (field_name = 'category' OR field_name = 'contenttype') AND french = 'e-Livres';"

    say "Change the FR category and contenttype 'Ultra e-Livres' to 'Ultra e-Livre'"
    @connection.execute "UPDATE `atg_moas_fr_mapping` SET french = 'Ultra e-Livre' WHERE (field_name = 'category' OR field_name = 'contenttype') AND french = 'Ultra e-Livres';"

    say "Change the FR category and contenttype 'Jeux éducatifs' to 'Jeu éducatif'"
    @connection.execute "UPDATE `atg_moas_fr_mapping` SET french = 'Jeu éducatif' WHERE (field_name = 'category' OR field_name = 'contenttype') AND french = 'Jeux éducatifs';"

    say "Change the FR category and contenttype 'Vidéos éducatives' to 'Vidéo éducative'"
    @connection.execute "UPDATE `atg_moas_fr_mapping` SET french = 'Vidéo éducative' WHERE (field_name = 'category' OR field_name = 'contenttype') AND french = 'Vidéos éducatives';"

    say "Change the FR category and contenttype 'Livres interactifs' to 'Livre interactif'"
    @connection.execute "UPDATE `atg_moas_fr_mapping` SET french = 'Livre interactif' WHERE (field_name = 'category' OR field_name = 'contenttype') AND french = 'Livres interactifs';"

    say "Change the FR category and contenttype 'Vidéos pour s'amuser' to 'Vidéo pour s'amuser'"
    @connection.execute "UPDATE `atg_moas_fr_mapping` SET french = 'Vidéo pour s\\'amuser' WHERE (field_name = 'category' OR field_name = 'contenttype') AND french = 'Vidéos pour s\\'amuser';"
  end
end
