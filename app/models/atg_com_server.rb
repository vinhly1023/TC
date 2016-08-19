class AtgComServer < ActiveRecord::Base
  def self.atg_upload_com_server(com_server_file)
    return ModelCommon.error_message('Please select Excel/CSV Hostname file to upload.') unless com_server_file

    com_server_content = ModelCommon.open_spreadsheet com_server_file
    return ModelCommon.error_message('Please make sure COM Server file format is Excel/CSV.') unless com_server_content

    headers = ModelCommon.downcase_array_key com_server_content.row(1)
    pre_headers = ['env', 'hostname']
    return ModelCommon.error_message("Please make sure COM Server file header includes: #{pre_headers.join(', ')}") unless (pre_headers - headers).empty?

    message = ''
    AtgComServer.new.transaction do
      begin
        # Delete all data
        AtgComServer.delete_all

        # Import data row by row
        (2..com_server_content.last_row).each do |i|
          AtgComServer.create(env: com_server_content.row(i)[0], hostname: com_server_content.row(i)[1])
        end
        message = ModelCommon.success_message 'ATG COM Server is uploaded successfully.'
      rescue => e
        message = ModelCommon.error_message("Error while uploading data: <br>#{e.message}")
        raise ActiveRecord::Rollback
      end
    end

    message
  end

  def self.atg_com_server_data
    AtgComServer.pluck(:env, :hostname)
  end

  def self.server_names(env)
    servers = AtgComServer.where(env: env)
    return [''] if servers.nil?

    hostname_arr = []
    servers.each do |s|
      hostname_arr.push s[:hostname]
    end

    hostname_arr
  rescue
    ['']
  end
end
