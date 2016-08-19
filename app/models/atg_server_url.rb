class AtgServerUrl < ActiveRecord::Base
  def self.atg_upload_server_url(server_url_file)
    content = ModelCommon.open_spreadsheet server_url_file
    return ModelCommon.error_message('Please make sure Server URL file format is Excel/CSV.') unless content

    headers = ModelCommon.downcase_array_key content.row(1).map(&:strip)
    return ModelCommon.error_message('Please make sure Server URL file header includes "env, URL".') unless (headers - ['env', 'url']).empty?

    message = ''
    AtgServerUrl.new.transaction do
      begin
        AtgServerUrl.delete_all

        (2..content.last_row).each do |i|
          AtgServerUrl.create(env: content.row(i)[0], url: content.row(i)[1])
        end
        message = ModelCommon.success_message 'ATG Server URL file is uploaded successfully.'
      rescue => e
        message = ModelCommon.error_message("Error while uploading data: <br>#{e.message}")
        raise ActiveRecord::Rollback
      end
    end

    message
  end

  def self.atg_server_url_data
    AtgServerUrl.pluck(:env, :url)
  end
end
