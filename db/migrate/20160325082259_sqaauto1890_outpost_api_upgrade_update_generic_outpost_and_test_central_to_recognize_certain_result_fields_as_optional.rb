class Sqaauto1890OutpostApiUpgradeUpdateGenericOutpostAndTestCentralToRecognizeCertainResultFieldsAsOptional < ActiveRecord::Migration
  def up
    say 'SQAAUTO-1890 Outpost API Upgrade: Update generic outpost and Test Central to recognize certain result fields as optional'

    say 'Migrate Schedule data: testsuite=>test_suite, testcases=>test_cases, emaillist=>email_list'

    schedules = Schedule.all
    unless schedules
      say 'Schedule is empty, nothing needs to update'
      return
    end

    failed_update_sch = []
    schedules.each do |sch|
      begin
        sch[:data][:test_suite] = sch[:data][:testsuite]
        sch[:data][:test_cases] = sch[:data][:testcases]
        sch[:data][:email_list] = sch[:data][:emaillist]

        sch[:data].except! :testsuite, :testcases, :emaillist

        failed_update_sch.push sch[:id] unless sch.save
      rescue => e
        say e.message
      end
    end

    say "Could not update data of scheduler id(s): #{failed_update_sch}. You should delete them manually." unless failed_update_sch.blank?
  end

  def down
    say 'Down >>> SQAAUTO-1890 Outpost API Upgrade: Update generic outpost and Test Central to recognize certain result fields as optional'

    say 'Migrate Schedule data: test_suite=>testsuite, test_cases=>testcases, email_list=>emaillist'

    schedules = Schedule.all
    unless schedules
      say 'Schedule is empty, nothing needs to update'
      return
    end

    failed_update_sch = []
    schedules.each do |sch|
      begin
        sch[:data][:testsuite] = sch[:data][:test_suite]
        sch[:data][:testcases] = sch[:data][:test_cases]
        sch[:data][:emaillist] = sch[:data][:email_list]

        sch[:data].except! :test_suite, :test_cases, :email_list

        failed_update_sch.push sch[:id] unless sch.save
      rescue => e
        say e.message
      end
    end

    say "Could not update data of scheduler id(s): #{failed_update_sch}. You should delete them manually." unless failed_update_sch.blank?
  end
end
