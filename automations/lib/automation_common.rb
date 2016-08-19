require 'nokogiri'

class PinRedemption
  def self.get_pin_number(env, code_type, status)
    pin = Connection.my_sql_connection("select pin_number from pins where env = '#{env}' and code_type = '#{code_type}' and status = '#{status}' limit 1").first
    return '' if pin.blank?
    pin['pin_number']
  end

  def self.get_pin_info(env, code_type, status)
    pin = Connection.my_sql_connection("select env, code_type, pin_number, platform, location, amount, currency, status  from pins where env = '#{env}' and code_type = '#{code_type}' and status = '#{status}' limit 1").first
    return {} if pin.blank?
    pin
  end

  def self.update_pin_status(env, code_type, pin_number, status)
    Connection.my_sql_connection("update pins set status = '#{status}' where env = '#{env}' and code_type = '#{code_type}' and pin_number = '#{pin_number}'")
  end
end

class ATGConfiguration
  def self.atg_configuration_data
    data = Connection.my_sql_connection('select data from atg_configurations order by updated_at desc limit 1').first
    return {} if data.nil?

    JSON.parse(data['data'], symbolize_names: true)
  end

  # Data is hash table: e.g. {'device_store' => 'LFC', 'payment_type' => 'Account Balance'}
  def self.override_atg_data(data)
    path = $LOAD_PATH.detect { |path| path.index('data.xml') }
    xml_content = Nokogiri::XML(File.read(path))

    data.each do |d|
      xml_content.search("//#{d[0]}")[0].inner_html = d[1]
    end

    File.open(path, 'w') { |f| f.print(xml_content.to_xml) }
  end
end
