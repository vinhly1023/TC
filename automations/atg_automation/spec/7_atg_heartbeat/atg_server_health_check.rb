require File.expand_path('../../spec_helper', __FILE__)

=begin
ATG Health check: Verify ATG server urls alive
=end

feature "ATG Server Health Check - #{General::ENV_CONST}", js: true do
  urls_data = Connection.my_sql_connection("select env, url from atg_server_urls where env = '#{General::ENV_CONST}'")

  urls_data.each do |server|
    status_code = LFCommon.get_http_code(server['url']).to_s
    it "URL: #{server['url']} ( status code: #{status_code})" do
      expect(status_code).to eq('200')
    end
  end
end
