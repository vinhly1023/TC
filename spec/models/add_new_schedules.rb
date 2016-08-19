require 'spec_helper'

class ScheduleUnitTest
  describe 'Run Schedule Checking' do
    sch_atg = nil
    sch_ws = nil

    context 'TC01 - Add new some ATG schedules into schedules table' do
      it 'Add new ATG schedule - repeat minutes' do
        schedule_count = Schedule.count
        Schedule.new.add_schedule(silo: 'ATG', note: 'Add new ATG schedule - repeat minutes', data: { silo: 'ATG', webdriver: 'FIREFOX', env: 'UAT', locale: 'US', test_suite: '43', test_cases: '219,226', release_date: '', email_list: 'ltrc_vn@leapfrog.test', description: '' }, start_time: '2015-01-12 00:01:00'.to_datetime, minute: 30, weekly: '', user_id: 6, location: 'unit_test_tc_uniq')
        expect(Schedule.count).to eq(schedule_count + 1)
      end

      it 'Add new ATG schedule - repeat weekly' do
        schedule_count = Schedule.count
        sch_atg = Schedule.new
        Schedule.new.add_schedule(silo: 'ATG', note: 'Add new ATG schedule - repeat weekly', data: { silo: 'ATG', webdriver: 'FIREFOX', env: 'UAT', locale: 'US', test_suite: '43', test_cases: '219,226', release_date: '', email_list: 'ltrc_vn@leapfrog.test', description: '' }, start_time: '2015-01-12 00:01:00'.to_datetime, minute: '', weekly: '2,4,6', user_id: 6, location: 'unit_test_tc_uniq')
        expect(Schedule.count).to eq(schedule_count + 1)
      end
    end

    context 'TC02 - Add new some WS schedules into schedules table' do

      it 'Add new WS schedule - repeat minutes' do
        schedule_count = Schedule.count
        Schedule.new.add_schedule(silo: 'WS', note: 'Add new WS schedule - repeat minutes', data: { silo: 'WS', webdriver: '', env: 'QA', locale: '', test_suite: '25', test_cases: '113', release_date: '', email_list: 'ltrc_vn@leapfrog.test', description: 'run WS' }, start_time: '2015-01-12 00:01:00'.to_datetime, minute: 30, weekly: '', user_id: 5, location: 'unit_test_tc_uniq')
        expect(Schedule.count).to eq(schedule_count + 1)
      end

      it 'Add new WS schedule - repeat weekly' do
        schedule_count = Schedule.count
        Schedule.new.add_schedule(silo: 'WS', note: 'Add new WS schedule - repeat weekly', data: { silo: 'WS', webdriver: '', env: 'QA', locale: '', test_suite: '25', test_cases: '113', release_date: '', email_list: 'ltrc_vn@leapfrog.test', description: 'run WS' }, start_time: '2015-01-12 00:01:00'.to_datetime, minute: '', weekly: '1,2,3,4,5', user_id: 5, location: 'unit_test_tc_uniq')
        expect(Schedule.count).to eq(schedule_count + 1)
      end
    end

    after :all do
      Schedule.destroy_all(location: 'unit_test_tc_uniq')
    end
  end
end
