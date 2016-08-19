require 'spec_helper'
require 'rspec'

describe 'TestCentral - Router/Links checking' do
  context DashboardController, type: :controller do
    it 'Check GET #dashboard/index' do
      get :index
      response.should be_success
    end

    it 'Check GET #dashboard/refresh_env' do
      get :refresh_env
      response.should be_success
    end

    it 'Check GET #dashboard/env_versions' do
      get :env_versions
      response.should be_success
    end

    it 'Check GET #view/daily' do
      assert_routing '/view/daily', controller: 'dashboard', action: 'daily', date: ''
    end
  end

  context AccountsController, type: :controller do
    it 'Check GET #accounts/clear_account' do
      request.session[:user_role] = 1
      get :clear_account, commit: nil
      response.should be_success
    end

    it 'Check GET #accounts/link_devices' do
      request.session[:user_role] = 1
      get :link_devices
      response.should be_success
    end

    it 'Check GET #accounts/process_linking_devices' do
      get :process_linking_devices,
          atg_ld_env: 'QA',
          atg_ld_email: 'ltrc_atg_uat_us_empty_1231201495346@sharklasers.com',
          atg_ld_password: '123456',
          atg_ld_platform: 'leappad2',
          atg_ld_autolink: 'true',
          atg_ld_children: '',
          atg_ld_deviceserial: ''

      response.should be_success
    end

    it 'Check GET #accounts/fetch_customer' do
      request.session[:user_role] = 1
      get :fetch_customer
      response.should be_success
    end
  end

  context UsersController, type: :controller do
    qa_acc = "ltrc_qa_test_#{SecureRandom.hex(5)}@leapfrog.test"

    it 'Check POST #user/sign_in' do
      post :sign_in,
           user_email: 'test',
           user_password: 'pass'
      response.should be_success
    end

    it 'Check GET #user/sign_out' do
      get :sign_out
      expect(response).to redirect_to('/users/sign_in')
    end

    it 'Check GET #user/create' do
      request.session[:user_role] = 1
      get :create
      response.should be_success
    end

    it 'Check POST #user/create' do
      request.session[:user_role] = 1
      post :create, commit: 'Create'

      response.should be_success
    end

    it 'Check POST #user/sign_up' do
      post :sign_up,
           email: qa_acc,
           first_name: 'LTRC',
           last_name: 'VN',
           password: '123456'

      response.should be_success
    end

    it 'Check POST #user/edit' do
      post :edit,
           email: qa_acc,
           first_name: 'LTRC',
           last_name: 'VN',
           password: '123456',
           role_id: '3',
           is_active: '1'

      response.should be_success
    end

    it 'Check GET #users/help' do
      request.session[:user_role] = 1
      get :help
      expect(response).to be_success
    end

    it 'Check GET /users/help/download' do
      expect(get: '/users/download?file=guides%2Frails+deployment%2FRails+Application+Deployment.docx').to be_routable
    end

    it 'Check GET /users/help/view_markdown/:file' do
      expect(get: '/users/help/view_markdown/guides/Outposts_API.md').to be_routable
    end

    after :all do
      user_obj = User.find_by(email: qa_acc)
      UserRoleMap.find_by(user_id: user_obj[:id]).destroy unless user_obj[:id].nil?
      PublicActivity::Activity.destroy_all owner_id: user_obj.id
      user_obj.destroy
    end
  end

  context AtgsController, type: :controller do
    it 'Check GET #atgs/atg_tracking_data' do
      get :atg_tracking_data,
          env: 'UAT',
          loc: 'US'

      response.should be_success
    end

    it 'Check GET #atgs/create_ts' do
      get :create_ts,
          tsname: 'Test Content',
          tcs: '219,220,',
          tsId: '43'

      response.should be_success
    end

    it 'Check GET #atgs/atgconfig' do
      request.session[:user_role] = 1
      get :atg_configuration
      response.should be_success
    end

    it 'Check GET #atgs/upload_code' do
      request.session[:user_role] = 1
      get :upload_code
      response.should be_success
    end

    it 'Check POST #atgs/upload_code' do
      request.session[:user_role] = 1
      post :upload_code,
           env: 'QA',
           code_type: 'USV1'

      response.should be_success
    end
  end

  context AtgMoasImportingsController, type: :controller do
    it 'Check GET #atg_moas_importings/index' do
      request.session[:user_role] = 1
      get :index
      response.should be_success
    end

    it 'Check POST #atg_moas_importings/excel2mysql' do
      post :excel2mysql,
           language: 'english',
           excel_file: nil,
           excel_catalog_file: nil,
           ymal_file_param: nil

      response.should be_success
    end
  end

  context DeviceLookupController, type: :controller do
    it 'Check GET #device_lookup/index' do
      request.session[:user_role] = 1
      get :index
      response.should be_success
    end
  end

  context GeoipLookupController, type: :controller do
    it 'Check GET #geoip_lookup/index' do
      request.session[:user_role] = 1
      get :index
      response.should be_success
    end
  end

  context PinsController, type: :controller do
    it 'Check GET #utilities/redeem_pin' do
      request.session[:user_role] = 1
      get :redeem_pin
      response.should be_success
    end

    it 'Check GET #pin_status' do
      request.session[:user_role] = 1
      get :pin_status,
          env: 'QA',
          lf_pin: '3760-8170-9435-6418'

      response.should be_success
    end

    it 'Check POST #pin_status' do
      request.session[:user_role] = 1
      post :pin_status,
           env: 'QA',
           lf_pin: '3760-8170-9435-6418'

      response.should be_success
    end
  end

  context RailsAppConfigController, type: :controller do
    it 'Check GET #rails_app_config/configuration' do
      request.session[:user_role] = 1
      get :configuration
      response.should be_success
    end

    it 'Check POST #rails_app_config/update_run_queue_option' do
      post :update_run_queue_option,
           limit_number: '9',
           refresh_rate: '2'

      response.should be_success
    end

    it 'Check POST #rails_app_config/update_email_queue_setting' do
      post :update_email_queue_setting,
           email_refresh_rate: '5'

      response.should be_success
    end

    it 'Check POST #rails_app_config/update_smtp_settings' do
      post :update_smtp_settings,
           address: 'smtp.gmail.com',
           port: '587',
           domain: 'testcentral.com',
           username: 'lflgautomation@gmail.com',
           password: '123456abc!',
           attachment_type: 'none'

      response.should be_success
    end

    it 'Check POST #rails_app_config/update_outpost_settings' do
      post :update_outpost_settings, outpost_refresh_rate: '10'
      response.should be_success
    end
  end

  context EmailRollupController, type: :controller do
    email = "ltrc_vn_test_#{SecureRandom.hex(5)}@testcentral.test"
    password = SecureRandom.hex(5)

    before :all do
      User.new(first_name: 'unit', last_name: 'test', email: email, password: password, is_active: 1).create_user(1)
      @dashboard_rollup = EmailRollup.find(1)
    end

    it 'Check GET #email_rollup/index' do
      request.session[:user_role] = 1
      get :index
      response.should be_success
    end

    it 'Check POST #email_rollup/configure_rollup_email' do
      request.session[:user_email] = email
      post :configure_rollup_email,
           type: 'dashboard',
           enabled: 'true',
           time_amount: '10',
           start_time: '01:30 PM',
           emails: ''

      response.should be_success
    end

    after :all do
      user = User.find_by(email: email)
      UserRoleMap.find_by(user_id: user[:id]).destroy
      EmailRollup.update(1, repeat_min: @dashboard_rollup.repeat_min, start_time: @dashboard_rollup.start_time, from_time: @dashboard_rollup.from_time, emails_list: @dashboard_rollup.emails_list, status: @dashboard_rollup.status)
      PublicActivity::Activity.destroy_all owner_id: user[:id]
      user.destroy
    end
  end

  context SchedulerController, type: :controller do
    sch = nil

    before :all do
      sch = Schedule.create(
        name: 'ATG',
        description: 'run ATG',
        data: { silo: 'ATG', browser: 'FIREFOX', env: 'UAT', locale: 'US', test_suite: '43', test_cases: '219,226', release_date: '', email_list: 'ltrc_vn@leapfrog.test', description: '' },
        start_date: '2015-01-12 00:01:00'.to_datetime,
        repeat_min: 30,
        weekly: '',
        user_id: 6,
        status: 0,
        location: 'unit_test_tc_uniq'
      )
    end

    it 'Check GET #index' do
      request.session[:user_role] = 1
      get :index
      response.should be_success
    end

    it 'Check POST #scheduler/update_scheduler_status' do
      post :update_scheduler_status,
           id: sch.id,
           status: '0'

      expect(response).to redirect_to('/admin/scheduler')
    end

    it 'Check POST #scheduler/update_scheduler_location' do
      post :update_scheduler_location,
           id: sch.id,
           location: sch.location + '_updated'

      expect(response).to redirect_to('/admin/scheduler')
    end

    after :all do
      sch.destroy
    end
  end

  context SearchController, type: :controller do
    it 'Check GET #search/index' do
      get :index
      response.should be_success
    end
  end

  context StaticPagesController, type: :controller do
    it 'Check GET #static_pages/about' do
      get :about
      response.should be_success
    end
  end

  context StationsController, type: :controller do
    it 'Check GET #stations/index' do
      request.session[:user_role] = 1
      get :index
      response.should be_success
    end

    it 'Check POST #stations/update_machine_config' do
      get :update_machine_config,
          station_name: '',
          network_name: 'LGDN13012-W7D01',
          ip_address: 'localhost',
          port: '3000'

      response.should be_success
    end

    it 'Check GET #stations/station_list' do
      get :station_list
      response.should be_success
    end
  end

  context OutpostController, type: :controller do
    it 'Check GET #outpost/upload_result' do
      get :upload_result, silo_name: 'narnia'
      response.should be_success
    end

    it 'Check POST #outpost/upload_result' do
      post :upload_result, silo_name: 'narnia'
      response.should be_success
    end

    it 'Check GET #outpost/outpost_config' do
      get :outpost_config, silo_name: 'narnia'
      response.should be_success
    end

    it 'Check POST #outpost/outpost_config' do
      post :outpost_config, silo_name: 'narnia'
      response.should be_success
    end

    it 'Check GET #outpost/refresh' do
      get :refresh
      response.should be_success
    end

    it 'Check POST #outpost/update_file' do
      post :update_file
      response.should be_success
    end

    it 'Check GET /outpost/test_suites' do
      get :test_suites, outpost: 4
      response.should be_success
    end
  end

  context Rest::V1::ApiController, type: :controller do
    it 'Check POST /rest/v1/sso' do
      post :sso, email: '', password: ''
      response.should be_success
    end

    it 'Check POST /rest/v1/upload_outpost_json_file' do
      post :upload_outpost_json_file
      response.should be_success
    end

    it 'Check POST /rest/v1/register' do
      post :register, api: {}
      response.should be_success
    end

    it 'Check POST /rest/v1/email_queue' do
      post :add_email_queue, email_list: '', run_id: ''
      response.should be_success
    end
  end

  context RunController, type: :controller do
    it 'Check GET /run/test_case_list' do
      get :test_case_list, test_suite: 57
      response.should be_success
    end

    it 'Check GET /run/status' do
      get :status
      response.should be_success
    end
  end

  context ActivityTrackingController, type: :controller do
    it 'Check GET #user/logging' do
      get :logging
      response.should be_success
    end

    it 'Check POST #users/update_limit' do
      post :update_limit, limit_log_paging: 'not change which user made change'
      expect(response).to redirect_to('/users/logging')
    end
  end
end
