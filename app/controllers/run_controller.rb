class RunController < ApplicationController
  include ViewHelper

  def index
    @selected_silo = params['silo_name']
    @outpost_silos = Outpost.outpost_run_options
    @run_data = params['run_data']
    render 'run/index'
  end

  def show_run_silo
    @silo = params['silo_name']
    @parent_suite = ''
    redirect_to 'dashboard/index' if @silo.blank?

    @outposts = Outpost.outposts @silo
    if @outposts.blank?
      @test_suites = Suite.test_suite_list(@silo, session[:user_role])
    else
      default_outpost = @outposts[0]
      @test_suites = Outpost.test_suite_list(default_outpost[0]).unshift('--- Select test suite ---')

      outpost = Outpost.find_by(id: default_outpost[0])
      @release_date_url = outpost[:outpost_apis]['release_date_url']
      @outpost_controls = view_context.generate_controls(default_outpost[1], {})
    end

    @station_info = Station.location_list
    @station_info[0][1] = 'DEFAULT'
    @station_info.unshift ['ANY', 'ANY']
    @station_selected = @station_info[0]

    render 'run/run_component', layout: false
  end

  def view_silo_group
    @selected_silo = params['silo_name']
    @outpost_silos = Outpost.outpost_view_options
    render 'run/view_silo_group'
  end

  def show_view_silo
    info = user_params

    @test_run = []
    @ds_groups = []
    @level = user_params[:level]
    @outpost_silos = Outpost.outpost_view_options
    @selected_silo = info[:silo_name]

    case @level
    when 0
      @silo = info[:silo_name]
      group = Run.to_silo @silo, info[:date]
      @test_group = group[:test_group]
      @current_date = group[:current_date]
      @previous_date = group[:previous_date]
      @next_date = group[:next_date]
    when 1
      lvl2 = Run.to_runs(info) || {}
      @test_run = lvl2[:test_runs] || []
      @group_name = lvl2[:group_name].to_s
      @ds_groups = lvl2[:ds_groups] || []
    else
      lvl3 = Run.to_cases(info) {}
      @test_script = lvl3[:test_script] || []
      @running_summary = lvl3[:running_summary].to_s
      @run_data = lvl3[:re_run_data]
      @name_lvl2 = lvl3[:name_lvl2].to_s
      suite_name = lvl3[:suite_name].to_s
    end

    @breadcrumbs = breadcrumbs_html info, suite_name

    render 'run/view_component', layout: false
  end

  def add_queue
    current_user_id = User.find_by(email: session[:user_email]).id
    silo = params[:silo]
    locales = params[:locale] || ['']
    description = params[:note].to_s
    test_suite = params[:test_suite]
    location = params[:station]

    if params[:com_server]
      com_server = AtgComServer.server_names params[:env]
    else
      com_server = ['']
    end

    init_data = Run.initialize_data params
    execute_data_lst = []

    case silo.upcase
    when 'ATG'
      test_cases = Run.add_case_to_suite params[:testrun]
      locales.each do |locale|
        com_server.each do |server|
          init_data.merge! test_cases
          init_data.merge!(com_server: server, locale: locale)
          execute_data_lst << init_data.clone
        end
      end
    when 'WS'
      test_suites = test_suite.to_s.split(',')
      is_all_ts = test_suites.count > 1

      test_suites.each do |ts|
        test_cases = is_all_ts ? CaseSuiteMap.get_test_cases(ts) : params[:testrun]

        init_data.merge! Run.add_case_to_suite test_cases
        init_data.merge!(test_suite: ts, suite_name: Suite.suite_name(ts))
        execute_data_lst << init_data.clone
      end
    when 'TC'
      init_data.merge! Run.add_case_to_suite params[:testrun]
      execute_data_lst << init_data
    else
      outpost_id = params[:outpost]
      test_suite = params[:test_suite]
      parent_suite = params[:parent_suite]
      outpost_info = Outpost.outpost_info(id: outpost_id)
      location = outpost_info[:name]

      outpost_data = {
        outpost: outpost_info,
        test_suite: test_suite,
        parent_suite: parent_suite
      }

      op_test_runs = []
      if test_suite == '--- All test suites ---'
        op_test_runs = Outpost.outpost_test_runs(params[:outpost], parent_suite)
      else
        op_test_runs.push(test_suite: test_suite, test_runs: params[:testrun])
      end

      op_test_runs.each do |tr|
        unless parent_suite.blank?
          outpost_data.merge!(test_suite: tr[:test_suite])
          init_data.merge!(test_suite: "#{parent_suite}/#{tr[:test_suite]}", suite_name: tr[:test_suite])
        end

        init_data.merge! Run.add_case_to_suite(tr[:test_runs], outpost_data)
        op_optional_params = Outpost.parameters(params[:outpost], params)

        op_optional_params.each do |op_params|
          init_data.merge! op_params
          init_data.merge!(op_optional_params: op_params.except(:search_text, :data_driven_csv))
          execute_data_lst << init_data.clone
        end
      end
    end

    if params[:start_time].blank?
      execute_data_lst.each do |data|
        current_date = Time.now.in_time_zone
        start_time = current_date + 90

        if data[:device_store].blank? && data[:payment_type].blank?
          Run.add_to_run_queue(
            data: data,
            location: Station.assign_station(location),
            date: current_date,
            created_at: current_date,
            user_id: current_user_id,
            status: Run::QUEUED_STATUS
          )
        else # Add 1-off schedule for 1 minute in the future
          sch = Schedule.new
          sch.add_schedule(
            silo: silo,
            note: description,
            data: data,
            start_time: start_time,
            weekly: '',
            user_id: current_user_id,
            location: location
          )

          Thread.new { sch.run_schedule sch.id }
        end
      end

      flash[:success] = 'Thank you! You will get the result after Test Scripts have been executed completely.'
    else
      start_time = params[:start_time]
      repeat = params[:repeat]
      minute = params[:minute]
      date_of_week = params[:dow].nil? ? '' : params[:dow].join(',')
      validate = Schedule.validate_params(start_time, repeat, minute, date_of_week)

      unless validate.blank?
        flash[:error] = validate.html_safe
        redirect_to :back
        return
      end

      error = ''
      execute_data_lst.each do |data|
        error << Schedule.new.add_schedule(
          silo: silo,
          note: description,
          data: data,
          start_time: start_time,
          minute: minute,
          weekly: date_of_week,
          user_id: current_user_id,
          location: location
        )
      end

      if error.blank?
        flash[:success] = 'Thank you! Your Schedule Test has been added successful.'
      else
        flash[:error] = error.html_safe
      end

      Thread.new { Schedule.new.run_schedule }
    end

    redirect_to :back
  rescue => e
    Rails.logger.error "Exception #{ModelCommon.full_exception_error e}"
  ensure
    begin
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection && ActiveRecord::Base.connection.active?
    rescue => e
      Rails.logger.error "Exception closing ActiveRecord db connection #{ModelCommon.full_exception_error e}"
    end
  end

  def delete
    view_path_parts = user_params[:view_path_parts]
    silo = params[:silo_name]
    level = user_params[:level]
    name_lvl1 = view_path_parts[0]
    view_url = ''
    back_to_url = "/#{silo}/view"
    deleted_runs = []

    if level == 1
      group_runs = Run.by_silo_group silo
      deleted_runs = group_runs[name_lvl1][:runs] unless group_runs[name_lvl1].nil?
    else
      group_runs = Run.by_group_name silo, name_lvl1
      back_to_url = "/#{silo}/view/#{group_runs[:group_name]}" if group_runs[:runs].count > 1
      deleted_runs << group_runs[:runs].detect { |x| x.name_lvl2 == user_params[:view_path].gsub(view_path_parts[0] + '/', '') } unless group_runs.blank? || group_runs[:runs].nil?

      if name_lvl1.include?('Devices[') && name_lvl1.include?('Payment Types[')
        view_url = "/#{silo}/view/#{name_lvl1.gsub(']', ', ]')}"

        deleted_runs.each do |run|
          view_url.gsub!("#{run.data['device_store']}, ", '') if group_runs[:runs].count { |group| group.data['device_store'] == run.data['device_store'] } == 1
          view_url.gsub!("#{run.data['payment_type']}, ", '') if group_runs[:runs].count { |group| group.data['payment_type'] == run.data['payment_type'] } == 1
        end

        view_url.gsub!(', ]', ']')
      end
    end

    deleted_runs.each do |r|
      r.create_activity key: 'run.destroy', owner: User.current_user
      r.destroy
    end

    view_url.blank? ? (redirect_to back_to_url) : (redirect_to URI.escape(view_url))
  end

  def user_params
    view_path = params[:view_path] || ''
    view_path.slice!(0) if view_path.start_with? '/'
    view_path_parts = view_path.split '/'
    level = view_path_parts.length

    {
      level: level,
      date: params[:date],
      silo_name: params[:silo_name],
      view_path: view_path,
      view_path_parts: view_path_parts
    }
  end

  def breadcrumbs_html(info, suite_name)
    breadcrumbs = [{ title: info[:silo_name], link: "/#{info[:silo_name]}/view" }]

    info[:view_path_parts].each_with_index do |n, i|
      path = info[:view_path_parts][0..i].join '/'
      title = i == 1 ? suite_name : n.tr('_', ' ')
      breadcrumbs << { title: title, link: "/#{info[:silo_name]}/view/#{path}" }
    end

    breadcrumbs.delete_at(breadcrumbs.length - 1) if info[:view_path].end_with?('.html')

    content = ''
    breadcrumbs.each_with_index do |n, i|
      is_end = i == (breadcrumbs.size - 1)
      content += '<small>' if i > 0
      content += "<a class=\"rp_body_a\" href=\"#{n[:link]}\">#{n[:title]}</a>"
      content += ' »' unless is_end
      content += '</small>' if i > 0
    end

    content
  end

  def download
    info = user_params
    run_ins = Run.new
    download_path = run_ins.create_zip_file info

    if download_path.nil? || !File.directory?(download_path)
      redirect_to :back
      return
    end

    send_file run_ins.zip_folder(download_path), type: 'application/zip', x_sendfile: true
  end

  def download_file
    format = params[:format]
    file = "#{params[:file_path]}.#{format}"
    send_file Rails.root.join('public', file), type: "application/#{format}", x_sendfile: true
  end

  def view_result
    info = user_params

    view_path_parts = info[:view_path_parts]
    file_name = view_path_parts[-1].gsub '.html', ''

    group_runs = Run.by_group_name info[:silo_name], view_path_parts[0]
    return unless group_runs

    runs = group_runs[:runs]
    temp_lv2 = view_path_parts[1..-2].join('/')
    run = runs.find { |r| r.name_lvl2 == temp_lv2 }
    return '' unless run

    run.reload
    @case = run.case_to_html(file_name) || ''

    suite_name = run.data['suite_name']
    @breadcrumbs = breadcrumbs_html info, suite_name

    render layout: true
  end

  def test_case_list
    test_suite = params[:test_suite]
    outpost = params[:outpost]

    if outpost.blank?
      child_ts_ids = SuiteMap.where(parent_suite_id: test_suite).map(&:child_suite_id)
      child_ts = Suite.where('id in (?)', child_ts_ids).order(order: :asc).pluck(:id, :name)
      test_cases = []
      test_cases = Case.joins(:case_suite_maps).where(case_suite_maps: { suite_id: test_suite }).order('case_suite_maps.order asc').pluck(:case_id, :name) unless test_suite.split(',').size > 1

      if child_ts.size > 0 && test_cases.size == 0
        tc_list = child_ts.unshift(['folder_type'], ['', '--- Select child test suite ---'], [child_ts_ids, '--- All test suites ---'])
      else
        tc_list = test_cases.unshift(['file_type'])
      end
    else
      tc_list = Outpost.test_case_list(outpost, test_suite, params[:parent_suite]).unshift(['file_type'])
    end

    render plain: tc_list
  end

  # GET /status/1.json
  def status
    render json: Run.status_json
  end
end
