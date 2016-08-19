module Op
  class Utility
    def self.upload_moas(outpost_name, language, moas_file, catalog_file, ymal_file)
      outpost = Outpost.api_outpost outpost_name
      return ModelCommon.error_message("The Outpost is not available: #{outpost_name}") if outpost.blank?

      request = RestClient::Request.new(
        method: :post,
        url: outpost[:outpost_apis]['upload_moas_url'],
        headers: { 'Content-Type' => 'application/json' },
        payload: {
          language: language,
          moas_file: moas_file,
          catalog_file: catalog_file,
          ymal_file: ymal_file
        },
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 30,
        timeout: 600
      )

      res = request.execute
      response = JSON.parse(res.body, symbolize_names: true)

      response[:status] ? ModelCommon.success_message(response[:message]) : ModelCommon.error_message(response[:message])
    rescue => e
      Rails.logger.error "ERROR WHILE IMPORTING MOAS FILES\n #{ModelCommon.full_exception_error e}"
      ModelCommon.error_message e.message
    end

    def self.platform_checker(outpost_name, language, content_platform_file)
      outpost = Outpost.api_outpost outpost_name
      return ModelCommon.error_message("The Outpost is not available: #{outpost_name}") if outpost.blank?

      request = RestClient::Request.new(
        method: :post,
        url: outpost[:outpost_apis]['platform_checker_url'],
        headers: { 'Content-Type' => 'application/json' },
        payload: {
          language: language,
          content_platform_file: content_platform_file
        },
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 30,
        timeout: 600
      )

      res = request.execute
      JSON.parse(res.body, symbolize_names: true)
    rescue => e
      Rails.logger.error "ERROR WHILE IMPORTING CHECKING CONTENT PLATFORM\n #{ModelCommon.full_exception_error e}"
      ModelCommon.error_message e.message
    end

    def self.update_file(upload_url, file_name, content)
      f_name = file_name.strip
      url = upload_url.strip + f_name
      msg = ''

      Dir.mktmpdir do |dir|
        temp_file = File.join(dir, f_name)
        File.write temp_file, content.strip
        request = RestClient::Request.new(
          method: :post,
          url: url,
          payload: { file: File.new(temp_file) },
          verify_ssl: OpenSSL::SSL::VERIFY_NONE
        )

        msg = request.execute
      end

      { status: true, message: msg }
    rescue => e
      Rails.logger.error "Error while updating file.\n#{ModelCommon.full_exception_error(e)}"
      { status: false, message: 'Error while updating file.' }
    end

    def self.file_content(url)
      request = RestClient::Request.new(
        method: :get,
        url: url,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      )

      request.execute
    end

    def self.supported_files(outpost_name)
      outpost = Outpost.api_outpost outpost_name
      return [] if outpost.blank?

      request = RestClient::Request.new(
        method: :get,
        url: outpost[:outpost_apis]['supported_files_url'],
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 8,
        timeout: 12
      )

      res = request.execute
      body_data = JSON.parse(res.body)

      return [] unless body_data['status']

      body_data['supported_files']
    rescue => e
      Rails.logger.error "EXCEPTION WHILE LOADING OUTPOST CONFIG\nURL: #{outpost[:outpost_apis]['supported_files_url']}\n #{ModelCommon.full_exception_error e}"
      []
    end

    def self.upload_file(json_content, user = nil, silo = nil)
      data = JSON.parse json_content

      # Validate all required fields in data JSON
      error = Outpost.validate_upload_data data
      return { status: false, message: error.join('<br>') } if error

      data['tc_version'] = '' if data['tc_version'].blank?

      # Getting user info by email as priority
      # 1. email key in json_content
      # 2. token[:email]
      # 3. email of login user
      temp_user = User.find_by(email: data['email'])
      if temp_user
        current_user = temp_user
      elsif user
        current_user = user
      else
        current_user = User.current_user
      end

      user_id = current_user.id
      data['user'] = current_user.first_name + ' ' + current_user.last_name
      data['email'] = current_user.email
      data['silo'] = silo if silo

      start_datetime = data['start_datetime']
      case_count = data['total_cases']
      percent_pass = data['total_passed'] / case_count
      note = data['note'] || ''
      run_id = data['run_id'] || ''

      if run_id.blank?
        run = Run.new(
          user_id: user_id,
          date: start_datetime,
          note: note,
          created_at: start_datetime,
          location: data['location']
        )
      else
        run = Run.where(id: run_id).first
        return { status: false, message: "The Run ID: #{run_id} does not exist" } if run.blank?
      end

      run[:percent_pass] = percent_pass
      run[:case_count] = case_count
      run[:data] = data
      run[:status] = 'done'

      # Handle in case of test is running so that Test Central can show status correctly
      if data['status'] == 'running'
        run[:case_count] = run[:percent_pass] = nil
        run[:status] = data['status']
      end

      run.save

      group_details = run.view_title_and_url
      { status: true, message: "<a href='#{group_details[:url]}'>#{group_details[:url]}</a>" }
    rescue JSON::ParserError
      { status: false, message: 'Invalid JSON format' }
    rescue => e
      Rails.logger.error ModelCommon.full_exception_error(e)
      { status: false, message: 'Error while uploading data' }
    end
  end
end
