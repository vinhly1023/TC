module Op
  class Promotion
    def self.code(outpost_name)
      outpost = Outpost.api_outpost outpost_name
      return ModelCommon.error_message("The Outpost is not available: #{outpost_name}") if outpost.blank?

      request = RestClient::Request.new(
        method: :get,
        url: outpost[:outpost_apis]['promotion_code_url'],
        headers: { 'Content-Type' => 'application/json' },
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 15,
        timeout: 30
      )

      res = request.execute
      response = JSON.parse(res.body, symbolize_names: true)

      response[:status] ? response[:promotion_code] : response[:message]
    rescue => e
      Rails.logger.error "ERROR WHILE GETTING PROMOTION CODE\n #{ModelCommon.full_exception_error e}"
      []
    end

    def self.upload_code(outpost_name, env, promotion_file)
      outpost = Outpost.api_outpost outpost_name
      return ModelCommon.error_message("The Outpost is not available: #{outpost_name}") if outpost.blank?

      request = RestClient::Request.new(
        method: :post,
        url: outpost[:outpost_apis]['promotion_code_url'],
        headers: { 'Content-Type' => 'application/json' },
        payload: {
          promotion_file: promotion_file,
          env: env
        },
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 15,
        timeout: 600
      )

      res = request.execute
      response = JSON.parse(res.body, symbolize_names: true)

      response[:status] ? ModelCommon.success_message(response[:message]) : ModelCommon.error_message(response[:message])
    rescue => e
      Rails.logger.error "ERROR WHILE UPLOADING PROMOTION CODE\n #{ModelCommon.full_exception_error e}"
      ModelCommon.error_message e.message
    end
  end
end
