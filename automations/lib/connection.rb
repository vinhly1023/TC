require 'mysql2'
require 'yaml'
require 'erb'

# This class initiate connection to MySql and execute queries
class Connection
  # get information from config/database.yml file
  erb = ERB.new(File.read('config/database.yml'))
  config = YAML.load(erb.result)[ENV['RAILS_ENV']]
  @server = config['host']
  @port = config['port']
  @database = config['database']
  @username = config['username']
  @password = config['password']

  def self.my_sql_connection(query_string)
    con = Mysql2::Client.new host: @server, username: @username, password: @password, database: @database, port: @port
    con.query "SET sql_mode = '';"  if query_string.upcase.include? 'GROUP BY'
    rs = con.query query_string
    con.close
    rs
  end

  def self.get_restful_output_by_restful_calls_id(restful_calls_id)
    con = Mysql2::Client.new host: @server, username: @username, password: @password, database: @database, port: @port
    rs =  con.query "select * from ws_restfulcalls_output where restfulcalls_id=#{restful_calls_id}"
    con.close
    rs
  end
end
