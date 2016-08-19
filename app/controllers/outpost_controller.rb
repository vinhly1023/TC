class OutpostController < ApplicationController
  def outpost_config
    @silo = params[:silo_name]
    @outposts = Outpost.outposts(@silo).map { |op| op[1] }
    @name = params[:outpost].nil? ? @outposts[0] : params[:outpost]
    @supported_file = @outposts.blank? ? [] : Op::Utility.supported_files(@name)
    outpost = Outpost.outpost_info name: @name
    if outpost
      apis = outpost[:outpost_apis] || {}
      @upload_url = apis['upload_url']
      @download_url = apis['download_url']
      @limit_running = outpost[:limit_running]
    else
      @upload_url = ''
      @download_url = ''
      @limit_running = ''
    end

    render 'config'
  end

  def file_content
    render plain: Op::Utility.file_content(params[:url])
  end

  def update_file
    render json: Op::Utility.update_file(params[:upload_url], params[:file_name], params[:content])
  end

  def upload_result
    @silo = params[:silo_name]

    return unless params['commit'] && params[:outpost_json]

    json_content = params[:outpost_json].read
    json_content = JSON.parse json_content
    json_content.delete('run_id')

    location = Outpost.where(silo: @silo).pluck(:name).first
    json_content['location'] = location.downcase
    json_content = JSON.generate(json_content)

    upload_result = Op::Utility.upload_file json_content, nil, @silo
    @message = upload_result[:status] ? ModelCommon.success_message(upload_result[:message]) : ModelCommon.error_message(upload_result[:message])
  rescue JSON::ParserError
    @message = ModelCommon.error_message 'Invalid JSON format'
  rescue => e
    @message = ModelCommon.error_message 'Error while uploading result'
    Rails.logger.error ModelCommon.full_exception_error(e)
  end

  def refresh
    Outpost.outpost_status
    render json: { status: 'done' }
  end

  def update_limit_running
    render html: Outpost.update_limit_running(params[:name], params[:limitRunning]).html_safe
  end

  def upload_pin
    @silo = params[:silo_name]
    @outposts = Outpost.outposts(@silo).map { |op| op[1] }
    @selected_op = params[:outpost] || @outposts[0]

    outpost_info = Outpost.outpost_info name: @selected_op
    apis = outpost_info[:outpost_apis] || {}
    @clean_pins_url = apis['clean_pins_url']

    @message = Op::Pin.upload(@selected_op, params[:pin_file], params[:env], params[:pin_type]) if params[:commit] && params[:pin_file]
    @pin_type = Op::Pin.types @selected_op
    @available_pins = Op::Pin.available_pins @selected_op

    render 'upload_pin'
  end

  def upload_moas
    @silo = params[:silo_name]
    @outposts = Outpost.outposts(@silo).map { |op| op[1] }
    @selected_op = params[:outpost] || @outposts[0]
    @message = Op::Utility.upload_moas(@selected_op, params[:language], params[:moas_file], params[:catalog_file], params[:ymal_file]) if params[:commit] && params[:moas_file]

    render 'upload_moas'
  end

  def platform_checker
    @silo = params[:silo_name]
    @outposts = Outpost.outposts(@silo).map { |op| op[1] }
    @selected_op = params[:outpost] || @outposts[0]

    if params[:commit] && params[:content_platform_file]
      platform_checking = Op::Utility.platform_checker(@selected_op, params[:language], params[:content_platform_file])
      @results = platform_checking[:results]
      @message = ModelCommon.error_message platform_checking[:message] unless platform_checking[:status]
    end

    render 'platform_checker'
  end

  def promotion_code
    @silo = params[:silo_name]
    @outposts = Outpost.outposts(@silo).map { |op| op[1] }
    @selected_op = params[:outpost] || @outposts[0]

    @message = Op::Promotion.upload_code(@selected_op, params[:env], params[:promotion_file]) if params[:commit] && params[:promotion_file]
    @promotion_data = Op::Promotion.code @selected_op

    render 'promotion_code'
  end

  def test_suite_instruction
    ts_instruction = ''

    outpost = Outpost.find_by(id: params[:outpost])
    ts_instruction = outpost.test_suite_metadata params[:test_suite] if outpost

    render html: ts_instruction.html_safe
  end

  def controls
    outpost = Outpost.find_by(id: params[:outpost])
    run_parameters = outpost[:run_parameters]

    test_suite = run_parameters.detect { |t| t[:name] == params[:test_suite] }
    controls = test_suite ? view_context.generate_controls(outpost[:name], test_suite['parameters']) : ''

    render plain: controls
  end

  def test_suites
    test_suites = Outpost.test_suite_list(params[:outpost], params[:parent_suite])

    unless test_suites.blank?
      test_suites = params[:is_refresh_outpost] ? test_suites.unshift('--- Select test suite ---') : test_suites.unshift('--- All test suites ---')
    end

    options = ''
    test_suites.each { |ts| options << '<option value="' + ts + '">' + ts + '</option>' }

    render plain: options
  end

  def release_date
    outpost_info = Outpost.outpost_info(id: params[:outpost_id])
    release_date_url = outpost_info[:outpost_apis][:release_date_url]

    render json: { status: true, release_date_url: release_date_url }
  end
end
