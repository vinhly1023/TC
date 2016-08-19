class Silo < ActiveRecord::Base
  has_many :suites

  def self.prepare_run_data(run)
    user_info = User.user_info_by_id(run[:user_id])
    run[:data][:username] = user_info[:full_name]
    run[:data][:current_time] = run[:data][:start_datetime] = Time.zone.now

    test_scripts = []
    run[:data][:test_cases].split(',').each do |id|
      test_scripts << Case.info(id)[:script_path]
    end
    run[:data][:test_cases] = test_scripts.reject(&:empty?)
    run[:data][:station_name] = Station.station_name run[:location]
    run
  end

  def self.silo_name_list
    silos = Silo.select(:name)
    return [] if silos.nil?

    silo_list = []
    silos.each do |silo|
      silo_list.push silo[:name]
    end

    silo_list
  end
end
