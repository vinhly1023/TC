require 'uri'
require 'rest-client'
require 'csv'

class Outpost < ActiveRecord::Base
  serialize :run_parameters, ApplicationHelper::JSONWithIndifferentAccess
  serialize :outpost_apis, ApplicationHelper::JSONWithIndifferentAccess
  serialize :menu_link, ApplicationHelper::JSONWithIndifferentAccess
  EDITABLE_FILE_TYPES = ['.json', '.txt', '.xml']
  READY_STATUS = 'Ready'
  RUNNING_STATUS = 'Running'
  ERROR_STATUS = 'Error'

  def self.register(data)
    message = validate_register_data(data)
    return { status: false, message: message } unless message.reject!(&:empty?).blank?

    station = Station.where(network_name: data[:name]).first
    return { status: false, message: "Outpost name is duplicated with an existing Station: #{data[:name]}" } unless station.nil?

    outpost = Outpost.where(name: data[:name]).first || Outpost.new(name: data[:name])
    outpost[:silo] = data[:silo]
    outpost[:ip] = data[:ip]
    outpost[:outpost_apis] = data[:outpost_apis]
    outpost[:limit_running] = data[:limit_running]
    outpost[:running_count] = data[:running_count]
    outpost[:run_parameters] = data[:run_parameters]
    outpost[:menu_link] = data[:menu_link]
    outpost.save

    outpost_info = Outpost.where(name: data[:name])
    { status: true, message: outpost_info }
  rescue => e
    Rails.logger.error ModelCommon.full_exception_error e
    { status: false, message: e.message }
  end

  def self.outpost_nav_options
    outposts = Outpost.select(:silo).distinct.order('silo asc')
    return [] if outposts.blank?

    outpost_arr = []
    outposts.each do |op|
      ready_outpost = Outpost.where('silo = ? and status != ?', op.silo, ERROR_STATUS)
      outpost = {
        silo: op.silo,
        title: op.silo.titleize.upcase,
        status: ready_outpost.blank? ? ERROR_STATUS : 'AVAILABLE', # AVAILABLE includes READY OR RUNNING
        result: false
      }

      all_name_based_on_silo = Outpost.select(:name).where(silo: op.silo).map(&:name)

      all_name_based_on_silo.each do |name|
        if Run.find_by location: name
          outpost.merge! result: true
          break
        end
      end

      outpost_arr.push outpost
    end

    outpost_arr
  end

  def self.menu_link_outposts
    outposts = Outpost.select(:silo, :menu_link).where('menu_link is not null').distinct.order('silo asc')
    return {} if outposts.blank?

    option_menu_link = {}
    outposts.each { |op| option_menu_link[op.silo] = op.menu_link }

    option_menu_link
  end

  def self.outpost_run_options
    outposts = Outpost.select(:silo).where('status != ?', ERROR_STATUS).distinct.order('silo asc')
    return [] if outposts.blank?

    outposts.map { |outpost| [outpost[:silo], outpost[:silo].titleize.upcase] }
  end

  def self.outpost_view_options
    outposts = Outpost.select(:silo).distinct.order('silo asc')
    return [] if outposts.blank?

    outpost_arr = []
    outposts.each do |op|
      # Get Outpost that has result in Run table
      all_name_based_on_silo = Outpost.select(:name).where(silo: op[:silo]).map(&:name)

      all_name_based_on_silo.each do |name|
        if Run.find_by location: name
          outpost_arr.push [op[:silo], op[:silo].titleize.upcase]
          break
        end
      end
    end

    outpost_arr
  end

  def self.outposts(silo)
    Outpost.where('silo = ? and status != ?', silo, ERROR_STATUS).pluck(:id, :name)
  end

  def self.outpost_info(query)
    Outpost.where(query).select(:id, :name, :silo, :ip, :status, :outpost_apis, :run_parameters, :limit_running).first
  end

  def self.group_outpost
    Outpost.select(:id, :silo, :name, :ip, :status).group_by { |o| o[:silo] }.values
  end

  def self.outpost_test_runs(outpost_id, parent_suite)
    run_parameters = Outpost.where(id: outpost_id).pluck(:run_parameters).first
    return [] if run_parameters.blank?

    test_suite = run_parameters.detect { |p| p[:name] == parent_suite }
    return [] unless test_suite && (test_suite[:test_cases] || test_suite[:child_suites])

    test_runs = []
    if test_suite[:child_suites]
      test_suite[:child_suites].each do |cs|
        tc_list = cs[:test_cases].map { |tc| tc[:path] }
        test_runs.push(test_suite: cs[:name], test_runs: tc_list)
      end
    elsif test_suite[:test_cases]
      tc_list = test_suite[:test_cases].map { |tc| tc[:path] }
      test_runs.push(test_suite: parent_suite, test_runs: tc_list)
    end

    test_runs
  end

  def self.test_suite_list(outpost_id, parent_suite = nil)
    run_parameters = Outpost.where(id: outpost_id).pluck(:run_parameters).first
    return [] if run_parameters.blank?

    return run_parameters.map { |p| p[:name] } if parent_suite.blank?

    suite = run_parameters.detect { |p| p[:name] == parent_suite }
    return [] unless suite && suite[:child_suites]

    suite[:child_suites].map { |s| s[:name] }
  end

  def self.test_case_list(outpost_id, test_suite, parent_suite = nil)
    run_parameters = Outpost.where(id: outpost_id).pluck(:run_parameters).first
    return [] if run_parameters.blank?

    suite = run_parameters.detect { |ts| ts[:name] == test_suite }
    return suite[:test_cases].map { |tc| [tc[:path], tc[:name]] } if suite && suite[:test_cases]

    parent_suites = run_parameters.detect { |ts| ts[:name] == parent_suite }
    return [] unless parent_suites && parent_suites[:child_suites]

    child_suites = parent_suites[:child_suites].detect { |cs| cs[:name] == test_suite }
    return [] unless child_suites && child_suites[:test_cases]

    child_suites[:test_cases].map { |tc| [tc[:path], tc[:name]] }
  end

  def self.sch_outpost_status
    $sch_outpost_status.jobs.each(&:unschedule)
    xml_content = Nokogiri::XML(File.read(RailsAppConfig.new.config_file))
    $outpost_refresh_rate = xml_content.search('//autoSetting/refreshOutpostStatus').text.to_i

    if $outpost_refresh_rate == 0
      Rails.logger.info "Stop refresh Outpost at: #{Time.now}"
      return
    end

    Rails.logger.info "Refresh Outpost status every #{$outpost_refresh_rate}s - CurrentTime: #{Time.now}"
    # Handle "Mysql::ProtocolError: invalid packet: sequence number mismatch" exception
    # :overlap => false
    # Since, by default, jobs are triggered in their own new thread, job instances might overlap. For example, a job that takes 10 minutes and is scheduled every 7 minutes will have overlaps.
    # To prevent overlap, one can set :overlap => false. Such a job will not trigger if one of its instance is already running.
    $sch_outpost_status.every "#{$outpost_refresh_rate}s", first_at: Time.now + $outpost_refresh_rate, overlap: false do
      Rails.logger.debug 'Refresh Outpost status: ' + Time.now.to_s
      outpost_status
    end
  rescue => e
    Rails.logger.error "Error while refreshing Outpost status #{ModelCommon.full_exception_error e}"
  end

  def self.outpost_status
    outposts = Outpost.select(:id, :name, :silo, :outpost_apis).where('outpost_apis IS NOT NULL and TRIM(outpost_apis) <> \'\'')
    return if outposts.blank?

    outposts.each do |op|
      begin
        begin
          request = RestClient::Request.new(
            method: :get,
            url: op[:outpost_apis]['status_url'],
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
            open_timeout: 8,
            timeout: 12
          )

          response_data = request.execute
          json_data = JSON.parse(response_data.body)

          if json_data['status'] && json_data['outpost']['name'] == op[:name]
            op[:status] = json_data['outpost']['outpost_status']
          else
            op[:status] = ERROR_STATUS
          end
        rescue => e
          op[:status] = ERROR_STATUS
          Rails.logger.error "Exception getting Outpost status (#{op[:name]}): #{e.message}"
        end

        op[:checked_at] = Time.zone.now
        op.save
      rescue => e
        Rails.logger.error "Exception updating Outpost status (#{op[:name]}):\n#{ModelCommon.full_exception_error e}"
      end
    end
  rescue => e
    Rails.logger.error "Exception Outpost Status scheduler #{ModelCommon.full_exception_error e}"
  ensure
    begin
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection && ActiveRecord::Base.connection.active?
    rescue => e
      Rails.logger.error "Exception closing ActiveRecord db connection #{ModelCommon.full_exception_error e}"
    end
  end

  def self.api_outpost(outpost_name)
    Outpost.where("name = '#{outpost_name}' and outpost_apis IS NOT NULL and TRIM(outpost_apis) <> ''").first
  end

  def self.execute(execute_endpoint, run_data)
    request = RestClient::Request.new(
      method: :post,
      url: execute_endpoint,
      headers: { 'Content-Type' => 'application/json' },
      payload: run_data.to_json,
      verify_ssl: OpenSSL::SSL::VERIFY_NONE
    )

    res = request.execute
    return res.body if res.body.include? '<html><head>'
    JSON.parse(res.body)
  end

  def self.validate_upload_data(data)
    return 'No data. Please re-check!' if data.blank?

    spec = {
      'silo' => :blank,
      'cases' => :blank,
      'suite_name' => :blank,
      'start_datetime' => :datetime,
      'end_datetime' => :datetime,
      'total_cases' => :integer,
      'total_passed' => :integer,
      'total_failed' => :integer,
      'total_uncertain' => :integer
    }
    spec.merge!('location' => :blank) if data['run_id'].blank?

    errors = []
    spec.each do |key, value|
      case value
      when :blank
        errors << "'#{key}' is missing or empty" if data[key].blank?
      when :datetime
        errors << "'#{key}' has invalid date time format" unless GeneralValidation.date_time_valid?(data[key])
      when :integer
        errors << "'#{key}' is not a valid integer number" unless data[key].is_a? Integer
      end
    end

    # validate first case data
    return errors if data['cases'].blank?
    first_case = data['cases'][0]
    case_spec = {
      'name' => :blank,
      'file_name' => :blank,
      'total_steps' => :integer,
      'total_failed' => :integer,
      'total_uncertain' => :integer,
      'steps' => :array
    }

    unless first_case.blank?
      case_spec.each do |key, value|
        case value
        when :blank
          errors << "case '#{key}' is missing or empty" if first_case[key].blank?
        when :integer
          errors << "case '#{key}' is not a valid integer number" unless first_case[key].is_a? Integer
        when :array
          errors << "case '#{key}' is not a valid array" unless first_case[key].is_a? Array
        end
      end
    end

    return errors if errors.size > 0
    nil
  end

  def self.silo_valid?(silo)
    return '' unless ['ATG', 'WS', 'TC'].include? silo
    'Silo can\'t be duplicated with TestCentral silos (ATG, WS, TC)'
  end

  def self.name_valid?(name)
    return '' if /\A[\w]+\z/ =~ name
    "Invalid Outpost name: #{name}. Only letters, numbers and underscores(_)"
  end

  def self.url_valid?(url)
    return '' if URI.regexp =~ url
    "Invalid status URL: #{url}"
  end

  def self.limit_running_valid?(limit_running)
    return 'limit_running is not a number' unless GeneralValidation.integer? limit_running
    return 'limit_running is less than 99' if limit_running.to_i > 99
    return 'limit_running is greater than 0' if limit_running.to_i < 1
    ''
  end

  def self.running_count_valid?(running_count)
    return 'running_count is not a number' unless GeneralValidation.integer? running_count
    return 'running_count is greater than or equal to 0' if running_count.to_i < 0
    ''
  end

  def self.validate_register_data(data)
    message = []
    message << name_valid?(data[:name])
    message << silo_valid?(data[:silo])
    message << url_valid?(data[:outpost_apis][:status_url])
    message << url_valid?(data[:outpost_apis][:exec_url])
    message << url_valid?(data[:outpost_apis][:parameters_url])
    message << limit_running_valid?(data[:limit_running])
    message << running_count_valid?(data[:running_count])
  end

  def self.parameters(id, args)
    return [{}] if args.blank?

    outpost = Outpost.find_by(id: id)
    return [{}] unless outpost

    suffix = outpost[:name].parameterize.underscore
    params = {}
    args.each do |k, v|
      params[k.chomp("_#{suffix}")] = v if k.end_with?(suffix)
    end

    outpost_input = params.symbolize_keys
    outpost_input[:data_driven_csv] = ModelCommon.upload_and_get_data_driven_csv(outpost_input[:data_driven_csv]).to_s if outpost_input[:data_driven_csv]
    array_inputs = outpost_input.select { |_, v| v.is_a? Array }.except(:payment_type, :device_store)

    return [outpost_input] if array_inputs.blank?

    outpost_input_arr = []
    ary = array_inputs.map { |k, v| [k].product v }
    ary.shift.product(*ary).map { |a| Hash[a] }.each { |o| outpost_input_arr << outpost_input.clone.merge!(o) }

    outpost_input_arr
  end

  def self.editable?(file)
    EDITABLE_FILE_TYPES.include? File.extname(file)
  end

  def case_name(tc_path, test_suite, parent_suite = '')
    run_param = self[:run_parameters]
    return if run_param.blank?

    suite = run_param.detect { |ts| ts[:name] == test_suite }
    if suite && suite[:test_cases]
      test_case = suite[:test_cases].detect { |tc| tc[:path] == tc_path }
      return test_case[:name] if test_case
    end

    parent_suites = run_param.detect { |ts| ts[:name] == parent_suite }
    return unless parent_suites && parent_suites[:child_suites]

    child_suites = parent_suites[:child_suites].detect { |cs| cs[:name] == test_suite }
    if child_suites && child_suites[:test_cases]
      test_case = child_suites[:test_cases].detect { |tc| tc[:path] == tc_path }
      return test_case[:name] if test_case
    end

    nil
  end

  def self.update_running_count(data)
    msg = running_count_valid? data[:running_count]
    return { status: false, message: msg } unless msg.empty?

    op = Outpost.find_by(name: data[:name])
    return { status: false, message: "Could not file Outpost name '#{data[:name]}'" } unless op

    op[:running_count] = data[:running_count]
    return { status: false, message: 'Error occurred while save Outpost data' } unless op.save

    { status: true, message: 'Successfully updated.' }
  end

  def self.update_limit_running(name, limit_running)
    # Pre-condition: validate
    msg = limit_running_valid? limit_running
    return ModelCommon.error_message(msg) unless msg.empty?

    # 1. Update Test Central database
    op = Outpost.find_by(name: name)
    return ModelCommon.error_message("Could not file Outpost name '#{name}'") unless op
    limit_running_before_updating = op[:limit_running]

    op[:limit_running] = limit_running
    return ModelCommon.error_message('Error occurred while save Outpost data') unless op.save

    # 2. Update the requested Outpost
    begin
      outpost_error_msg = ModelCommon.error_message 'Error occurred when updating limit running. You can update limit running manually by stopping the Outpost and then updating limit running in the Outpost config file.'

      request = RestClient::Request.new(
        method: :post,
        url: op[:outpost_apis]['limit_running_url'],
        headers: { 'Content-Type' => 'application/json' },
        payload: { limit_running: limit_running },
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      )

      res = JSON.parse(request.execute.body)
    rescue
      op['limit_running'] = limit_running_before_updating
      op.save
      return outpost_error_msg
    end

    # 3. Reset if any problems happen
    unless res['status']
      op['limit_running'] = limit_running_before_updating
      op.save
      return outpost_error_msg
    end

    ModelCommon.success_message 'Successfully updated.'
  end

  def test_suite_metadata(test_suite)
    run_parameters = self[:run_parameters]

    test_suite = run_parameters.detect { |t| t[:name] == test_suite }
    instruction = test_suite[:metadata][:instruction] if test_suite[:metadata]

    instruction || ''
  end
end
