require 'find'
require 'zip'
require 'open3'

class Run < ActiveRecord::Base
  include PublicActivity::Common
  include ViewRun
  serialize :data, ApplicationHelper::JSONWithIndifferentAccess
  belongs_to :users
  RUNNING_STATUS = 'running'
  QUEUED_STATUS = 'queued'
  ERROR_STATUS = 'error'
  DONE_STATUS = 'done'
  SCHEDULED_STATUS = 'scheduled'

  def self.status_text(total, passed, failed, uncertain)
    Rails.logger.debug "status_text >>> t#{total} p#{passed} f#{failed} u#{uncertain}"
    return 'N/A' if total == 0
    return 'Failed' if failed > 0
    return 'N/A' if uncertain > 0 || (!passed.nil? && passed != total)
    return 'Running' if passed.nil?
    'Passed'
  end

  def name_lvl1
    view_title_and_url[:parts][0]
  end

  def name_lvl2
    view_title_and_url[:parts][1]
  end

  def name_lv1_ds
    view_title_and_url[:part_w_ds]
  end

  def view_title_and_url(root_url = '')
    device_store = {}
    unless data[:device_store].nil?
      device_store[:device_store] = 'Devices[%s]'
      device_store[:payment_type] = 'Payment Types[%s]'
    end

    email = data[:email] || data[:schedule_info][:user_email]

    sub_parts_1 = {
      date: self[:date].in_time_zone.strftime('%Y-%m-%d'),
      email: email.split('@')[0],
      env: data[:env],
      com_server: data[:com_server],
      locale: data[:locale],
      release_date: data[:release_date],
      inmon_version: data[:inmon_version]
    }

    sub_parts_1.merge!(device_store)
    sub_parts_1.merge!(data[:op_optional_params].symbolize_keys.except(:payment_type, :device_store)) if data[:op_optional_params]
    sub_parts_1.reject { |_k, v| v.blank? }
    sub_parts_1[:release_date] = sub_parts_1[:release_date].tr(';', '|') if sub_parts_1[:release_date]
    part1 = sub_parts_1.values.join('_').gsub(/_{2,}/, '_').chomp '_'

    part2 = [
      data[:start_datetime].to_datetime.strftime('%H%M%S%L'),
      data[:suite_name].gsub(/[^0-9A-Za-z]/, '_').squeeze('_')
    ].join('_').gsub(/_{2,}/, '_').chomp '_'

    path = "#{data[:silo]}/view/#{part1}/#{part2}"
    root_url += '/'
    sta_cls = status_and_class

    ds_temp_path = sub_parts_1.merge(
      device_store: data[:device_store],
      payment_type: data[:payment_type]
    ) { |_k, _v1, v2| v2 }
    ds_temp_path.reject! { |_k, v| v.blank? }

    part_w_ds = ds_temp_path.values.join('_').gsub(/_{2,}/, '_').chomp '_'
    details = ds_temp_path.map { |_key, val| "#{val}" }[2..-1].join(', ')
    title = "#{data[:suite_name]} (#{details})"

    ds_part1 = ds_temp_path.values.join('_').gsub(/_{2,}/, '_').chomp '_'
    ds_url = root_url + "#{data[:silo]}/view/#{ds_part1}/#{part2}"

    {
      title: title,
      url: root_url + path,
      ds_url: ds_url,
      parts: [part1, part2],
      silo: data[:silo],
      status: sta_cls[:status].upcase,
      css_class: sta_cls[:css_class],
      part_w_ds: part_w_ds
    }
  end

  def duration
    if self[:status] == QUEUED_STATUS || self[:status] == SCHEDULED_STATUS
      ''
    elsif data['end_datetime'].nil? || data['start_datetime'].nil?
      'Calculating'
    else
      ((data['end_datetime'].to_datetime - data['start_datetime'].to_datetime) * 24 * 60).to_f.round(2).to_s + ' minutes'
    end
  end

  def status_and_class
    if self[:status] == DONE_STATUS || self[:status] == RUNNING_STATUS
      status = Run.status_text data['total_cases'], data['total_passed'], data['total_failed'], data['total_uncertain']
      status = 'Pending' if self[:percent_pass] != 0 && self[:percent_pass] != 1
    else
      status = self[:status]
    end

    css_class = status && status.parameterize.underscore || ''

    { status: status, css_class: css_class }
  end

  def suite_name
    (data['suite_name'].nil?) ? data['suite_path'] : data['suite_name'] # Handle for old data
  end

  def to_attach_file(root_url = '', type = 'zip')
    run_link = view_title_and_url root_url

    if data[:device_store].blank?
      view_path = run_link[:url].partition('/view/').last
    else
      view_path = run_link[:ds_url].partition('/view/').last
    end

    download_path = create_zip_file(silo_name: run_link[:silo], view_path: view_path)

    return Dir.glob(download_path + '/*') if type == 'html'
    zip_folder(download_path)
  end

  def create_zip_file(info)
    silo_name = info[:silo_name]
    arr_view_path = (info[:view_path].nil?) ? '' : info[:view_path].split('/')
    level = (arr_view_path.length == 0) ? 1 : arr_view_path.length + 1
    root_url = Rails.application.config.root_url

    if level == 2
      temp_runs = Run.by_group_name silo_name, info[:view_path]
      return '' unless temp_runs

      runs = temp_runs[:runs]
      return '' unless runs

      first_run = runs[0][:data]
      download_path = Dir.mktmpdir("#{first_run['silo']}_#{first_run['user']}_#{first_run['env']}_".parameterize.underscore)

      runs.each do |run|
        next if run[:status] == QUEUED_STATUS || run[:status] == SCHEDULED_STATUS

        sub_folder = File.join(download_path, run.name_lvl2)
        FileUtils.mkdir_p(sub_folder)
        cases = run.data['cases']

        # Generate summary html file
        html_details = run.to_html Rails.application.config.root_url
        run.generate_report_file(sub_folder, nil, run.data['email'], run.summary_html(root_url), html_details)

        return '' unless cases.each_with_index do |c, index|
          run.generate_report_file(sub_folder, run.id, c['file_name'], c['name'], index + 1)
        end
      end
    else
      group_results = Run.by_group_name silo_name, arr_view_path[0]
      return '' unless group_results

      runs = group_results[:runs]
      return '' unless runs

      run = runs.detect { |x| x.name_lvl2 == info[:view_path].gsub(arr_view_path[0] + '/', '') }
      return '' unless run
      cases = run.data['cases']

      # Generate summary html file
      run_data = run[:data]
      download_path = Dir.mktmpdir("#{run_data['silo']}_#{run_data['user']}_#{run_data['env']}_#{run_data['suite_name']}_".parameterize.underscore)
      html_details = run.to_html Rails.application.config.root_url
      run.generate_report_file(download_path, nil, run.data['email'], run.summary_html(root_url), html_details)

      return '' unless cases.each_with_index do |c, index|
        run.generate_report_file(download_path, run.id, c['file_name'], c['name'], index + 1)
      end
    end

    download_path
  end

  def zip_folder(folder)
    zipfile_name = "#{folder}.zip"

    Zip.setup do |c|
      c.continue_on_exists_proc = true # overwrite existing zip file
      c.unicode_names = true # for zip file name is unicode
    end

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      Find.find(folder) do |dir_or_file|
        zipfile.add(dir_or_file.sub(folder + '/', ''), dir_or_file) unless File.directory?(dir_or_file)
      end
    end

    zipfile_name
  end

  # Warning: JSON run.data is not loaded in Run objects. Use run.reload to load run.data.
  def self.by_silo_group(silo, start_date = nil, end_date = nil, email = nil, level = nil, view_path = nil)
    filter = []
    filter << "json_extract(data, '$.silo') = '\"#{silo}\"' COLLATE utf8_general_ci"
    filter << "date >= \"#{start_date}\"" if start_date
    filter << "date <= \"#{end_date}\"" if end_date
    filter << "json_extract(data, '$.email') like '%#{email}@%' COLLATE utf8_general_ci" if email

    columns = 'id, user_id, date, percent_pass, case_count, note, created_at, updated_at, status'
    step_paths = Array.new(30) { |i| "'$.cases[#{i}].steps'" }
    columns += ",json_remove(data, #{step_paths.join ','}) as data"

    runs = Run.select(columns).where(filter.join ' and ')

    f_groups = {}
    if level == 1 && !view_path.to_s.include?('Devices[')
      runs.each do |run|
        name = run.name_lv1_ds

        if f_groups[name].nil?
          f_groups[name] = { runs: [run] }
        else
          f_groups[name][:runs].push run
        end
      end
    else
      groups = {}
      runs.each do |run|
        run[:data][:email] = User.user_info_by_id(run[:user_id])[:email]
        name = run.name_lvl1

        if groups[name].nil?
          groups[name] = {
            runs: [run],
            device_store: [] | [run[:data][:device_store]],
            payment_type: [] | [run[:data][:payment_type]]
          }
        else
          unless run[:data][:device_store].nil?
            groups[name][:device_store] = groups[name][:device_store] | [run[:data][:device_store]]
            groups[name][:payment_type] = groups[name][:payment_type] | [run[:data][:payment_type]]
          end

          groups[name][:runs].push run
        end
      end

      groups.each do |k, v|
        if v[:device_store].empty?
          f_groups[k] = { runs: v[:runs] }
        else
          new_key = format(k, v[:device_store].join(', '), v[:payment_type].join(', '))
          f_groups[new_key] = { runs: v[:runs] }
        end
      end
    end

    f_groups
  end

  def self.by_group_name(silo, group_name)
    parts = group_name.split('_')
    start_date = parts[0].to_time.utc if parts.size > 0
    end_date = start_date + 1.days if parts.size > 0
    email = parts[1] if parts.size > 1

    groups = by_silo_group silo, start_date, end_date, email, 1, group_name
    groups_sch = Schedule.by_silo_group silo, start_date, end_date, email
    groups.deep_merge!(groups_sch) { |_key, v1, v2| v1 + v2 }

    group = groups[group_name]
    return if group.blank?

    group[:runs].each { |run| run.reload if run[:status] == DONE_STATUS || run[:status] == RUNNING_STATUS }
    { group_name: group_name, runs: group[:runs].sort_by { |run| run[:updated_at] }.reverse } unless group.blank?
  end

  def get_rspec_it(step)
    case step['status']
    when 'passed'
      generate_example_passed(step['name'], step['duration'])
    when 'failed'
      generate_example_failed(step['name'], step['duration'], step['exception']) + make_example_group_header_red
    when 'pending'
      generate_example_pending(step['name'])
    end
  end

  def self.runs_css_class(runs)
    arr_status = []
    runs.each do |run|
      if run[:status] == DONE_STATUS || run[:status] == RUNNING_STATUS
        counts = [run.data[:total_cases], run.data[:total_passed], run.data[:total_failed], run.data[:total_uncertain]]
        arr_status.push(Run.status_text counts[0], counts[1], counts[2], counts[3])
      else
        arr_status.push run[:status]
      end
    end

    case
    when arr_status.include?('Failed')
      status_class = 'class="failed"'
    when arr_status.include?('N/A')
      status_class = 'class="n_a"'
    when arr_status.include?('Running')
      status_class = 'class="running"'
    when arr_status.include?('Passed')
      status_class = 'class="passed"'
    when arr_status.include?('queued')
      status_class = 'class="queued"'
    when arr_status.include?('scheduled')
      status_class = 'class="scheduled"'
    else
      status_class = 'class="n_a"'
    end

    status_class.html_safe
  end

  def self.save_json_data(data)
    return if data['run_id'].blank?

    run = Run.find_by(id: data['run_id'])
    return unless run

    run.update(data: data)
  end

  def exec_testcentral_testcase
    $count_progress += 1
    sleep(rand(0.001..0.999))

    # Update run status to running and remove cases data
    self[:status] = RUNNING_STATUS
    data[:cases] = []
    save

    # Initialize run data
    Silo.prepare_run_data self

    if self[:data][:silo] == 'ATG'
      Atg.prepare_run_data data

      # Create new template file to contain data test
      temp_file = Tempfile.new([File.basename(ENV['ATG_XMLDATA_PATH']), File.extname(ENV['ATG_XMLDATA_PATH'])])
      File.open(temp_file, 'wb') { |f| f.write(File.read ENV['ATG_XMLDATA_PATH']) }
      data[:data_file] = temp_file.path

      data[:reset_data_xml] = proc do
        Rails.logger.info "reset_data_xml >>> account = #{data[:exist_acc]}"
        Atg.update_data_info_to_xml(data[:data_file], data)
      end
    elsif data[:silo] == 'WS'
      data[:inmon_version] = WebService.get_inmon_version data[:env]
      data[:spec_folder] = ENV['WEBSERVICE_LOADPATH'] + '/spec'

      # Create new template file to contain data test
      temp_file = Tempfile.new([File.basename(ENV['WEBSERVICE_XMLDATA_PATH']), File.extname(ENV['WEBSERVICE_XMLDATA_PATH'])])
      File.open(temp_file, 'wb') { |f| f.write(File.read ENV['WEBSERVICE_XMLDATA_PATH']) }
      data[:data_file] = temp_file.path

      data[:reset_data_xml] = proc do
        WebService.update_data_info_to_xml(data[:data_file], data)
      end
    elsif data[:silo] == 'TC'
      data[:spec_folder] = ENV['TC_LOADPATH']
    end

    run
    update(status: DONE_STATUS)

    # Add run result to Email Queue
    EmailQueue.create(run_id: id, email_list: data[:email_list])
  rescue => e
    update(status: ERROR_STATUS)
    Rails.logger.error "Exception while running tests #{ModelCommon.full_exception_error e}"
  ensure
    $count_progress -= 1
  end

  def exec_outpost_testcase
    sleep(rand(0.001..0.999))
    update(status: RUNNING_STATUS)

    data[:suite_name] = data[:test_suite]
    data[:note] = data[:description].to_s
    data[:station_name] = location
    data[:start_datetime] = Time.zone.now

    run
  rescue => e
    update(status: ERROR_STATUS)
    Rails.logger.error "Exception while running tests #{ModelCommon.full_exception_error e}"
  end

  def to_queued_html_row
    tc_params = {
      env: data[:env].to_s.upcase,
      locale: data[:locale],
      release_date: data[:release_date],
      com_server: data[:com_server],
      web_driver: data[:web_driver]
    }
    tc_params.merge!(data[:op_optional_params]) if data[:op_optional_params]
    test_info = tc_params.reject { |_k, v| v.blank? }.values.join('_')

    description = "<br>Description: #{self[:description]}" unless self[:description].blank?
    user_name = User.user_info_by_id(user_id)[:full_name]
    station = Station.station_name(location)
    station_name = station.blank? ? location : station

    <<-INTERPOLATED_HEREDOC.strip_heredoc
      <tr>
        <td>Queued</td>
        <td>#{station_name}</td>
        <td>
          User: #{user_name}<br>
          Test suite: #{data[:silo].titleize.upcase}/#{data[:suite_name]}<br>
          Test Info: #{test_info}
          #{description}
        </td>
      </tr>
    INTERPOLATED_HEREDOC
  end

  def run
    Rails.logger.info 'Starting test run'
    Rails.logger.debug "run_json >>> #{JSON.pretty_generate data}"

    outpost_info = Outpost.outpost_info(name: data[:station_name])

    if outpost_info.blank?
      run_test_central
    else
      run_outpost outpost_info[:outpost_apis]['exec_url']
    end

    Rails.logger.info 'Finished test run'
    create_activity key: 'run.create', owner: User.current_user
  end

  def run_test_central
    self[:data][:test_cases].each_with_index do |tc, tc_index|
      begin
        `ipconfig /flushdns` unless RbConfig::CONFIG['host_os'].include? 'darwin'

        json_temp_file = Tempfile.new(["#{tc.split('/').last.gsub('.rb', '')}", '.json'])
        json_temp_path = json_temp_file.path
        Rails.logger.info "json_temp_file.path >>> #{json_temp_path}"

        rspec_file = "#{data[:spec_folder]}/#{tc}"
        output_json_option = "-f LFJsonFormatter -r ./#{ENV['RSPEC_REPORT_LIB']}/lf_json_formatter -o #{json_temp_path}"

        if data[:data_file].nil?
          command = "rspec --require rspec/legacy_formatters #{rspec_file} #{output_json_option}"
        else
          command = "rspec --require rspec/legacy_formatters #{rspec_file} #{output_json_option} -I #{data[:data_file]}"
        end

        test_case_info = Case.get_case(data[:silo], tc)
        case_json = {
          name: test_case_info.name,
          description: test_case_info.description,
          file_name: tc.split('/').last,
          comment: Case.get_case_comment(rspec_file),
          total_steps: 1,
          total_failed: 0,
          total_uncertain: 0,
          steps: [{ name: '', steps: [] }]
        }

        data[:cases][tc_index] = case_json
        save

        begin
          Rails.logger.info "running test case >>> #{command}"

          if data[:reset_data_xml]
            Rails.logger.info 'calling reset_data_xml'
            data[:config] = data[:reset_data_xml].call
          end

          # update database after each step
          scheduler = Rufus::Scheduler.new

          data_refresh_thr = Thread.new do
            modified_time = File.mtime(json_temp_path)

            scheduler.every '5s', overlap: false do
              begin
                last_modified_time = File.mtime(json_temp_path)

                # Only update run data when JSON temp file is changed
                unless modified_time == last_modified_time
                  case_json.merge!(json_report_data json_temp_path)
                  case_json[:name] = test_case_info.name
                  case_json[:description] = test_case_info.description
                  data[:cases][tc_index] = case_json
                  save

                  modified_time = last_modified_time
                end
              rescue => e
                Rails.logger.error "Error while saving result data #{ModelCommon.full_exception_error e}"
              ensure
                begin
                  ActiveRecord::Base.connection.close if ActiveRecord::Base.connection && ActiveRecord::Base.connection.active?
                rescue => e
                  Rails.logger.error "Error while closing ActiveRecord db connection #{ModelCommon.full_exception_error e}"
                end
              end
            end
          end

          stdout_and_stderr_str, status = Open3.capture2e(command)
          fail "Status = #{status}\n" + stdout_and_stderr_str if File.zero? json_temp_file

          # ERROR : Mysql::ServerError::LockWaitTimeout: Lock wait timeout exceeded; try restarting transaction: UPDATE `runs` SET `data` = ?, `updated_at` = ? WHERE `runs`.`id` = ?
          begin
            if scheduler
              Rails.logger.info "Stop refreshing test result scheduler: #{File.basename json_temp_file}"
              scheduler.jobs.each(&:unschedule)
              scheduler.stop :kill
            end
          rescue => e
            Rails.logger.error "Couldn't stop scheduler #{ModelCommon.full_exception_error e}"
          ensure
            Thread.kill data_refresh_thr if data_refresh_thr
          end

          # Merge data from Json report to case json
          case_json.merge!(json_report_data json_temp_path)
          case_json[:name] = test_case_info.name
          case_json[:description] = test_case_info.description
        rescue => e
          full_error = ModelCommon.full_exception_error e
          full_error = "PLEASE CLEAN YOUR DISK THEN TRY TO RUN AGAIN\n" + full_error if e.message.downcase.include?('not enough space')
          case_json[:error] = full_error
          case_json[:total_uncertain] = 1
          case_json[:total_failed] = 0
          case_json[:total_steps] = 1
          Rails.logger.error "Error while running test cases: #{full_error}"
        end

        data[:cases][tc_index] = case_json

        if case_json[:total_failed] > 0
          data[:total_failed] += 1
        elsif case_json[:total_uncertain] == 0
          data[:total_passed] += 1
        else
          data[:total_uncertain] += 1
        end

        save

        total_steps_passed = case_json[:total_steps] - (case_json[:total_failed] + case_json[:total_uncertain])
        Rails.logger.info "Ran test case >>> #{tc}, total/pass/fail/uncertain #{case_json[:total_steps]}/#{total_steps_passed}/#{case_json[:total_failed]}/#{case_json[:total_uncertain]}"
      rescue => e
        Rails.logger.error "Error while running test cases #{ModelCommon.full_exception_error e}"
      end
    end

    data[:end_datetime] = Time.now
    self[:case_count] = data[:total_cases]
    self[:percent_pass] = data[:total_passed] / data[:total_cases]
    save
  end

  def json_report_data(json_file_path)
    raw_json = File.read json_file_path
    Rails.logger.info "#{File.basename json_file_path} file size: #{File.size json_file_path}"

    return {} if raw_json.empty?
    JSON.parse(raw_json, symbolize_names: true)
  end

  def run_outpost(execute_endpoint)
    data[:run_id] = self[:id]
    Outpost.execute(execute_endpoint, data)
    data[:cases] = []
    save
  end

  def self.run_queue_by_schedule_id(schedule_id)
    Run.where("status = ? and (json_extract(data, '$.schedule_info.id')) = ?", QUEUED_STATUS, schedule_id)
  end

  def self.add_to_run_queue(data)
    run = Run.new data

    unless run.save
      Rails.logger.info "Error while adding queue to Run:\n#{run.errors.full_messages.inspect}"
    end
  end

  def self.initialize_data(params)
    data_driven_csv = ModelCommon.upload_and_get_data_driven_csv(params[:data_driven_csv])

    init_data = {
      email: User.current_user.email,
      silo: params[:silo],
      tc_version: "#{$tc_version[:date]}_#{$tc_version[:version]}",
      test_suite: params[:test_suite],
      suite_name: Suite.suite_name(params[:test_suite]),
      email_list: params[:user_email],
      description: params[:note].to_s,
      start_datetime: Time.zone.now,
      total_passed: 0,
      total_failed: 0,
      total_uncertain: 0,
      cases: []
    }

    init_data[:test_cases] = params[:testrun].join(',') if params[:testrun]
    init_data[:total_cases] = params[:testrun].size if params[:testrun]
    init_data[:env] = params[:env] if params[:env]
    init_data[:web_driver] = params[:webdriver] if params[:webdriver]
    init_data[:locale] = params[:locale] if params[:locale]
    init_data[:com_server] = params[:com_server] if params[:com_server]
    init_data[:data_driven_csv] = data_driven_csv unless data_driven_csv.blank?
    init_data[:device_store] = params[:device_store] if params[:device_store]
    init_data[:payment_type] = params[:payment_type] if params[:payment_type]
    init_data[:release_date] = params[:release_date] if params[:release_date]

    init_data
  end

  def self.to_silo(silo, date, view_path = nil)
    test_group = []
    if date
      start_date = DateTime.strptime(date, '%Y-%m')
    else
      start_date = Date.today.at_beginning_of_month
    end

    end_date = start_date + 1.months

    current_date = start_date.strftime '%Y-%m'
    previous_date = (start_date - 1.months).strftime '%Y-%m'
    next_date = (start_date + 1.months).strftime '%Y-%m'

    groups = Run.by_silo_group silo, start_date, end_date, nil, view_path
    groups_sch = Schedule.by_silo_group silo, start_date, end_date
    groups.deep_merge!(groups_sch) { |_key, v1, v2| v1 + v2 }

    groups.values.each do |value|
      value[:status] = Run.runs_css_class value[:runs]
    end

    groups = groups.sort.reverse

    groups.each do |group|
      gb_status = group[1][:runs].group_by { |run| run[:status] }
      gb_status.each { |k, v| gb_status[k] = v.size }
      gb_status = gb_status.map { |k, v| "#{v} #{'item'.pluralize v} #{k}" }.join(', ')

      test_group << { name: "#{group[0]} (#{gb_status})", path: group[0], silo: silo, css_class: group[1][:status] }
    end

    { test_group: test_group, current_date: current_date, previous_date: previous_date, next_date: next_date }
  end

  def self.to_runs(info)
    group_runs = Run.by_group_name info[:silo_name], info[:view_path]
    return unless group_runs

    runs = group_runs[:runs]
    return unless runs

    test_run = []
    if runs[0][:data][:device_store].nil?
      runs.each do |run|
        test_run << { path: "#{info[:view_path]}/#{run.name_lvl2}", run: run, silo: info[:silo_name] }
      end
    else
      group_name = group_runs[:group_name]
      ds_groups = runs.group_by { |run| run[:data][:schedule_info][:id] unless run[:data][:schedule_info].nil? }
    end

    { test_runs: test_run, group_name: group_name, ds_groups: ds_groups }
  end

  def self.to_cases(info)
    view_path_parts = info[:view_path_parts]
    group_runs = Run.by_group_name info[:silo_name], view_path_parts[0]
    return {} unless group_runs

    runs = group_runs[:runs]
    return {} unless runs

    name_lvl2 = view_path_parts[1..(view_path_parts.length - 1)].join('/')
    run = runs.find { |x| x.name_lvl2 == name_lvl2 }
    return unless run

    suite_name = run.data['suite_name']
    running_summary = run.summary_html
    cases = run.data['cases']
    return {} if cases.blank?

    test_script = []
    cases.each do |c|
      test_script.push(run.case_row_data(c).merge! duration: c['duration'], device_store: run[:data][:device_store])
    end

    { name_lvl2: name_lvl2, suite_name: suite_name, running_summary: running_summary, test_script: test_script, re_run_data: run.re_run_data }
  end

  def self.status_json
    current_time = Time.now.in_time_zone

    begin
      status_hash = {
        queued: Run.where(status: QUEUED_STATUS).length,
        today: Run.where('status != ? AND created_at >= ? AND created_at <= ? ', QUEUED_STATUS, current_time.beginning_of_day.utc, current_time.end_of_day.utc).length,
        scheduled: Schedule.where(status: 1).length,
        running: $count_progress,
        outpost: Run.where('status = ? and location in (?)', RUNNING_STATUS, Outpost.where("status != '#{ERROR_STATUS}'").pluck(:name)).length
      }
      status_hash.to_json
    rescue => e
      Rails.logger.error "Exception while refreshing run statuses #{ModelCommon.full_exception_error e}"
    ensure
      begin
        ActiveRecord::Base.connection.close if ActiveRecord::Base.connection && ActiveRecord::Base.connection.active?
      rescue => e
        Rails.logger.error "Exception while closing ActiveRecord db connection #{ModelCommon.full_exception_error e}"
      end
    end
  end

  # For view queue and schedule
  def self.add_case_to_suite(test_runs, op_info = {})
    test_runs ||= []
    cases = []

    test_runs.each do |tc_id|
      tc_name = op_info[:outpost].blank? ? Case.info(tc_id)[:name] : op_info[:outpost].case_name(tc_id, op_info[:test_suite], op_info[:parent_suite])

      cases.push(
        name: tc_name,
        tc_path: tc_id,
        total_steps: 1,
        total_failed: 0,
        total_uncertain: 0,
        steps: [{ name: '', steps: [] }]
      )
    end

    { test_cases: test_runs.join(','), total_cases: test_runs.size, cases: cases }
  end

  def re_run_data
    run_data = {}

    run_data[:silo] = data[:silo]
    run_data[:test_suite] = (data['suite_name'].nil?) ? data['suite_path'] : data['suite_name']
    run_data[:locale] = data['locale'].upcase if data['locale'] && data['locale'].to_s.strip != ''
    run_data[:release_date] = data['release_date'].upcase if data['release_date'] && data['release_date'].to_s.strip != ''
    run_data[:browser] = data['web_driver'].upcase if data['web_driver'] && data['web_driver'].to_s.strip != ''
    run_data[:env] = data['env'].upcase if data['env'] && data['env'].to_s.strip != ''
    run_data[:testcase] = data['cases'].map { |c| c[:name] }.join(';') if data['cases'] && data['cases'].to_s.strip != ''
    run_data[:device_store] = data['device_store'] if data['device_store'] && data['device_store'].to_s.strip != ''
    run_data[:payment_type] = data['payment_type'] if data['payment_type'] && data['payment_type'].to_s.strip != ''

    run_data.to_json
  end
end
