module Op
  class Pin
    def self.types(outpost_name)
      outpost = Outpost.api_outpost outpost_name
      return ModelCommon.error_message("The Outpost is not available: #{outpost_name}") if outpost.blank?

      request = RestClient::Request.new(
        method: :get,
        url: outpost[:outpost_apis]['pin_types_url'],
        headers: { 'Content-Type' => 'application/json' },
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 15,
        timeout: 30
      )

      res = request.execute
      response = JSON.parse(res.body, symbolize_names: true)
      response[:pin_types]
    rescue => e
      Rails.logger.error "ERROR WHILE LOADING PIN TYPES\n #{ModelCommon.full_exception_error e}"
      []
    end

    def self.upload(outpost_name, pin_file, env, pin_type)
      outpost = Outpost.api_outpost outpost_name
      return ModelCommon.error_message("The Outpost is not available: #{outpost_name}") if outpost.blank?

      request = RestClient::Request.new(
        method: :post,
        url: outpost[:outpost_apis]['upload_pin_url'],
        headers: { 'Content-Type' => 'application/json' },
        payload: {
          pin_file: pin_file,
          pin_type: pin_type,
          env: env
        },
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 15,
        timeout: 600
      )

      res = request.execute
      response = JSON.parse(res.body, symbolize_names: true)

      if response[:status]
        ModelCommon.success_message response[:message]
      else
        ModelCommon.error_message response[:message]
      end
    rescue => e
      Rails.logger.error "ERROR WHILE IMPORTING PIN FILE\n #{ModelCommon.full_exception_error e}"
      ModelCommon.error_message e.message
    end

    def self.available_pins(outpost_name)
      outpost = Outpost.api_outpost outpost_name
      return ModelCommon.error_message("The Outpost is not available: #{outpost_name}") if outpost.blank?

      request = RestClient::Request.new(
        method: :get,
        url: outpost[:outpost_apis]['available_pins_url'],
        headers: { 'Content-Type' => 'application/json' },
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 15,
        timeout: 30
      )

      res = request.execute
      response = JSON.parse(res.body, symbolize_names: true)
      response[:available_pins]
    rescue => e
      Rails.logger.error "ERROR WHILE GETTING AVAILABLE PINS\n #{ModelCommon.full_exception_error e}"
      []
    end
  end
end
