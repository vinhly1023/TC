require 'spec_helper'
require 'rspec'

describe 'TestCentral - Function' do
  email = "ltrc_vn_test_#{SecureRandom.hex(5)}@testcentral.test"
  password = SecureRandom.hex(5)
  session_email = nil

  before :all do
    User.new(first_name: 'unit', last_name: 'test', email: email, password: password, is_active: 1).create_user(3)
  end

  context UsersController, type: :controller do
    it 'Login: should redirect to dashboard page' do
      post :sign_in, user_email: email, user_password: password
      session_email = session[:user_email]
      expect(response).to redirect_to('/dashboard/index')
    end

    it 'Session is created' do
      expect(session_email).to eq email
    end
  end

  context RunController, type: :controller do
    it 'Request execute WS tests: 7 - Heartbeat Checking/2. LeapTV Heartbeat Checking' do
      request.session[:user_email] = email
      request.env['HTTP_REFERER'] = '/WS/run'
      post :add_queue, silo: 'WS', test_suite: 49, env: 'QA', webdriver: 'FIREFOX', testrun: [318], station: 'unit_test_tc_uniq'
      expect(response).should redirect_to '/WS/run'
    end

    it 'Request execute ATG tests: 1 - English ATG Web Content/1. Web English - Search SKU and product detail checking' do
      request.session[:user_email] = email
      request.env['HTTP_REFERER'] = '/ATG/run'
      post :add_queue, silo: 'ATG', test_suite: 45, env: 'PREVIEW', webdriver: 'FIREFOX', locale: ['US'], release_date: '1999-01-01', testrun: [256], station: 'unit_test_tc_uniq'
      expect(response).should redirect_to '/ATG/run'
    end

    after :all do
      Run.destroy_all(location: 'unit_test_tc_uniq')
    end
  end

  after :all do
    user = User.find_by(email: email)
    UserRoleMap.find_by(user_id: user[:id]).destroy
    PublicActivity::Activity.destroy_all owner_id: user[:id]
    user.destroy
  end
end
