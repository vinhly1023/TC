class Pin < ActiveRecord::Base
  VALID_PIN_REGEX = /^[0-9]{4}\-{0,1}[0-9]{4}\-{0,1}[0-9]{4}\-{0,1}[0-9]{4}\-{0,1}$/
  validates :pin_number, presence: true, format: { with: VALID_PIN_REGEX, multiline: true }

  def self.upload_pin_file(pin_file, env, code_type)
    return ModelCommon.error_message('Please select Excel/CSV pin file to upload.') unless pin_file

    pin_content = ModelCommon.open_spreadsheet pin_file
    return ModelCommon.error_message('Please make sure pin file format is Excel/CSV.') unless pin_content

    pin_headers = ModelCommon.downcase_array_key pin_content.row(1)
    pre_headers = ['id', 'status']
    return ModelCommon.error_message("Please make sure pin file header includes: #{pre_headers.join(', ')}") unless (pre_headers - pin_headers).empty?

    message = ''
    Pin.new.transaction do
      begin
        # Import data row by row
        (2..pin_content.last_row).each do |i|
          row_i = pin_content.row(i)
          row_header = Hash[[pin_headers, row_i].transpose]

          # If PIN exist -> update PIN status to PIN excel file, else -> add new PIN record
          pin_exist = Pin.where(env: env, code_type: code_type, pin_number: row_header['id'])

          if pin_exist.empty?
            Pin.create(
              env: env,
              code_type: code_type,
              pin_number: row_header['id'],
              platform: row_header['platform'],
              location: row_header['location'],
              amount: row_header['amount'],
              currency: row_header['currency'],
              status: row_header['status'])
          else
            pin_exist.update_all(status: row_header['status'])
          end
        end

        message = ModelCommon.success_message 'Pins are uploaded successfully.'
      rescue => e
        message = ModelCommon.error_message("Error while uploading data: <br>#{e.message}")
        raise ActiveRecord::Rollback
      end
    end

    message
  end
end
