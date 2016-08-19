require 'net/http'
require 'nokogiri'
require 'parallel'
require 'uri'

class DashboardController < ApplicationController
  skip_before_filter :grant_permission
  def index
    @current_time = Time.now.in_time_zone

    # get env versions and show on dashboard
    env_versions
    @test_outposts = Outpost.group_outpost
    @test_stations = Station.station_list_html(true)
    @silos = Silo.silo_name_list
    Outpost.outpost_view_options.each { |o| @silos.push(o[0]) }

    if session[:user_role] == 1
      runs_data = Run.where('status != ?', Run::QUEUED_STATUS).order(created_at: :desc).limit(5)
    else
      @silos.delete('TC')
      runs_data = Run.where("status != ? AND json_extract(data, '$.silo') != ?", Run::QUEUED_STATUS, 'TC').order(created_at: :desc).limit(5)
    end

    @run_data = {
      queued: {
        runs: Run.where(status: Run::QUEUED_STATUS).order(:created_at),
        type: 'queued'
      },
      recent: {
        runs: runs_data,
        links: [{ name: 'daily results', url: 'view/daily' }]
      },
      today: {
        runs: Run.where('status != ? AND created_at >= ? AND created_at <= ? ', Run::QUEUED_STATUS, @current_time.beginning_of_day.utc, @current_time.end_of_day.utc),
        url: 'view/daily',
        hide_list: true
      },
      scheduled: {
        runs: Schedule.where(status: 1).order(next_run: :asc),
        links: [{ name: 'edit', url: admin_scheduler_path }]
      }
    }
  end

  def daily
    date = params[:date].blank? ? Time.now.in_time_zone.strftime('%Y-%m-%d') : params[:date].delete('/')
    @current_date = Date.parse date
    @previous_date = @current_date - 1.days
    @next_date = @current_date + 1.days
    @test_run_content = Dashboard.new.testrun_summary nil, false, '', date
  end

  def env_versions
    @envs = []
    @apps = []
    @services = []
    @last_updated_env = ''

    # get env version from env_versions table
    last_record = EnvVersion.last
    return unless last_record

    @services = JSON.parse(last_record.services, symbolize_names: true)[:services]
    @envs = @services.map { |service| service[:env] }.uniq
    @apps = @services.map { |service| service[:name] }.uniq
    @last_updated_env = last_record.updated_at.strftime(Rails.application.config.time_format) unless last_record.updated_at.to_s.empty?
  end

  def refresh_env(ajax = true)
    @services = JSON.parse(File.read('config/env_version.json'), symbolize_names: true)[:services]
    @envs = @services.map { |service| service[:env] }.uniq
    @apps = @services.map { |service| service[:name] }.uniq
    @services.each { |s| Dashboard.expand_services(s) }

    Parallel.each(@services, in_threads: 10) { |s| s[:endpoints].each { |e| Dashboard.http_fetch_contents(e) } }

    @services.each { |s| s[:endpoints].each { |e| e[:first_version] = e[:body] && Dashboard.first_version(e[:body]) } }

    # delete :body key of endpoint
    @services.each { |service| service[:endpoints].map! { |endpoint| endpoint.reject { |e| e == :body } } }

    EnvVersion.create(services: { services: @services }.to_json)

    return '0' unless ajax
    render plain: '1'
  end

  def delete_outpost
    Outpost.destroy params[:id]
    render json: { status: 'OK' }
  end

  def filter_results
    case params['section']
    when 'recent'
      render html: Dashboard.recent_result(params['silo']).html_safe
    when 'queued'
      render html: Dashboard.queued_list(params['silo']).html_safe
    when 'scheduled'
      render html: Dashboard.scheduled_list(params['silo']).html_safe
    else
      render html: ''.html_safe
    end
  end
end
