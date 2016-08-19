class ReadXML
  attr_reader :config_file

  def initialize
    @config_file = File.join(Dir.tmpdir, "#{Time.now.strftime('%Y%m%d%H%M%S')}_config.xml")
    FileUtils.cp("#{File.expand_path File.dirname(__FILE__)}/../config/config.xml", @config_file)
  end

  def smtp_info
    xml_content = File.read @config_file
    doc = Nokogiri::XML(xml_content)
    { address: doc.search('//address').text,
      port: doc.search('//port').text,
      domain: doc.search('//domain').text,
      username: doc.search('//username').text,
      password: doc.search('//password').text,
      attachment_type: doc.search('//attachmentType').text }
  end

  def run_queue_info
    xml_content = File.read @config_file
    doc = Nokogiri::XML(xml_content)
    { limit_run_test: doc.search('//limitRunningTest').text,
      refresh_run_rate: doc.search('//refreshRunningRate').text }
  end

  def delete_config_file
    FileUtils.rm_f @config_file
  end
end
