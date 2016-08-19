class Dashboard
  attr_accessor :domain

  # load some recent test runs on dashboard page
  def testrun_summary(from_time = nil, only_schedules = false, root_url = '', current_date_time = nil)
    content = ''

    if from_time.nil?
      if current_date_time.nil?
        runs = Run.order(updated_at: :desc).limit(5)
      else
        current_date_time_start = current_date_time.in_time_zone.beginning_of_day
        current_date_time_end = current_date_time_start.end_of_day
        runs = Run.where('created_at >= ? AND created_at <= ? ', current_date_time_start.utc, current_date_time_end.utc).order(created_at: :desc)
      end
    else
      runs = Run.where('created_at > ?', from_time.in_time_zone.utc).order(created_at: :desc)
    end

    runs.each do |r|
      # Show only run which has been executed by active-schedules
      next if r.data['schedule_info'].nil? && only_schedules
      content << r.to_html_row(root_url)
    end

    content
  end

  def self.recent_result(silo_list)
    return '' unless silo_list

    if silo_list == 'ALL'
      runs = Run.where("status != '#{Run::QUEUED_STATUS}'").order(id: :desc).limit(5)
    else
      silo_params = silo_query silo_list
      runs = Run.where(silo_params).where("status != '#{Run::QUEUED_STATUS}'").order(id: :desc).limit(5)
    end

    runs_html = ''
    runs.each { |run| runs_html += run.to_html_row }

    runs_html
  end

  def self.queued_list(silo_list)
    return '' unless silo_list

    if silo_list == 'ALL'
      queues = Run.where("status = '#{Run::QUEUED_STATUS}'").order(:created_at)
    else
      silo_params = silo_query silo_list
      queues = Run.where(silo_params).where("status = '#{Run::QUEUED_STATUS}'").order(:created_at)
    end

    queues_html = ''
    queues.each { |q| queues_html += q.to_queued_html_row }

    queues_html
  end

  def self.scheduled_list(silo_list)
    return '' unless silo_list

    if silo_list == 'ALL'
      schedules = Schedule.where(status: 1).order(next_run: :asc)
    else
      silo_params = silo_query silo_list
      schedules = Schedule.where(silo_params).where(status: 1).order(next_run: :asc)
    end

    schedules_html = ''
    schedules.each { |q| schedules_html += q.to_html_row }

    schedules_html
  end

  def self.silo_query(silo_list)
    filter = []
    args = []
    silos = []

    silo_list.each do |silo|
      filter << '(json_extract(data, ?)) = ?'
      args << '$.silo' << "#{silo.strip}"
    end

    silos << filter.join(' or ')
    silos += args
    silos
  end

  def self.first_version(version_file_contents)
    result = version_file_contents.lines.first.chomp.split(':')[2] || version_file_contents.lines.first.chomp.split(':')[1]
    return result if result

    html_doc = Nokogiri::HTML(version_file_contents)
    "Bamboo:#{html_doc.xpath('//table/tr[2]/td[3]/b').text} SVN:#{html_doc.xpath('//table/tr[2]/td[2]/b').text}"
  end

  def self.expand_services(config)
    config[:endpoints] = []
    config[:instances].split(',').each { |i| config[:endpoints] << { first_version: '', port: '', subdomain: '', url: "#{config[:protocol] || 'http://'}#{i}.leapfrog.com#{config[:path]}" } }

    config[:vips].each { |n| config[:endpoints] << { first_version: '', port: '', subdomain: '', url: n } } if config[:vips]
  end

  def self.http_fetch_contents(endpoint)
    uri = URI.parse(endpoint[:url])
    endpoint[:subdomain] = uri.host.rpartition('.leapfrog.com')[0]
    endpoint[:port] = uri.port

    begin
      Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
        request = Net::HTTP::Get.new uri
        response = http.request request
        response.code != '200' && endpoint[:error] = "HTTP status error: #{response.code}"
        endpoint[:body] = response.body unless endpoint[:error]
      end
    rescue EOFError, Errno::ECONNRESET, Errno::EINVAL, Errno::ETIMEDOUT, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError, SocketError, Timeout::Error, Errno::ECONNABORTED => e
      endpoint[:error] = e.class.name
    rescue Errno::ECONNREFUSED
      endpoint[:error] = 'Network permission denied'
    end
  end
end
