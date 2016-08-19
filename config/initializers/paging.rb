begin
  xml_content = Nokogiri::XML(File.read(RailsAppConfig.new.config_file))
  $limit_paging_items = xml_content.search('//pagingSetting/loggingPageLimit').text.to_i
  $limit_paging_items = 15 if $limit_paging_items > 100 || $limit_paging_items < 1
rescue
  $limit_paging_items = 15
end
