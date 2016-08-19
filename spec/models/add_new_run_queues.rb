require 'spec_helper'

class RunQueueUnitTest
  describe 'Run Queue Checking' do
    # Set variable
    user_email = "ltrc_vn_test_#{SecureRandom.hex(5)}@testcentral.test"
    password = SecureRandom.hex(5)
    user_id = nil
    ws_data = { silo: 'WS', webdriver: '', env: 'QA', locale: '', test_suite: '25', test_cases: '113', release_date: '', email_list: 'ltrc_vn_test@leapfrog.test', description: 'run WS' }
    atg_data = { silo: 'ATG', webdriver: 'FIREFOX', env: 'UAT', locale: 'US', test_suite: '43', test_cases: '219,226', release_date: '', email_list: 'ltrc_vn_test@leapfrog.test', description: '' }
    run = nil
    run_count1 = nil
    run_count2 = nil
    status = 'queued'

    # Pre-condition: Create a new user
    before :all do
      User.new(first_name: 'unit', last_name: 'test', email: user_email, password: password, is_active: 1).create_user(1)
      user_id = User.find_by(email: user_email).id
    end

    context 'TC01 - Add a WebService Queue into Run Queues' do
      before :all do
        run_count1 = Run.count(status: status)
        run = Run.create(data: ws_data, status: status, user_id: user_id, location: 'unit_test_tc_uniq')
        run_count2 = Run.count(status: status)
      end

      it 'Verify WebService Queue is added successfully' do
        expect(run_count2).to eq(run_count1 + 1)
      end

      after :all do
        run.destroy
      end
    end

    context 'TC02 - Add a ATG Queue into Run Queues' do
      before :all do
        run_count1 = Run.count(status: status)
        run = Run.create(data: atg_data, status: status, user_id: user_id, location: 'unit_test_tc_uniq')
        run_count2 = Run.count(status: status)
      end

      it 'Verify ATG Queue is added successfully' do
        expect(run_count2).to eq(run_count1 + 1)
      end

      after :all do
        run.destroy
      end
    end

    after :all do
      User.find_by(id: user_id).destroy
      UserRoleMap.find_by(user_id: user_id).destroy
      PublicActivity::Activity.destroy_all owner_id: user_id
    end
  end
end
