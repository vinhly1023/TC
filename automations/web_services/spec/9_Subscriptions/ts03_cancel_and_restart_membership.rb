require File.expand_path('../../spec_helper', __FILE__)

=begin
Subscriptions: Webservices - Login account - cancel membership and restart
=end

describe "TS03 - Webservices - Login account - cancel membership and restart - #{Misc::CONST_ENV}" do
  exist_email = 'ltrcvn2015102716303661sbgroupf01@leapfrog.test'
  invalid_email = 'ltrcvn2015102716303661sbgroupf01invalid@leapfrog.test'
  new_email = 'ltrcvn2015102913332744sbgroupf01@leapfrog.test'
  password = '123456'

  context 'Service: Login account' do
    message = 'The email address or password you entered is incorrect. Please try again.'

    context '1. Login with invalid email' do
      res_login = nil

      it "Login account( email:#{invalid_email}, password:#{password})" do
        res_login = login_sub_account(invalid_email, password)
      end

      it "Verify server returns error message 'The email address or password you entered is incorrect. Please try again.'" do
        expect(res_login[:body]['error']['details'][0]).to eq(message)
      end
    end

    context '2. Login with invalid password' do
      res_login_1 = nil

      it "Login account( email:#{exist_email}, password:1234567)" do
        res_login_1 = login_sub_account(exist_email, '1234567')
      end

      it "Verify server returns error message 'The email address or password you entered is incorrect. Please try again.'" do
        expect(res_login_1[:body]['error']['details'][0]).to eq(message)
      end
    end

    context '3. Login account that already signed up' do
      res_login_2 = nil

      it "Login account( email:#{exist_email}, password:#{password})" do
        res_login_2 = login_sub_account(exist_email, password)
      end

      it 'Verify user is able to login sucessful' do
        expect(res_login_2[:body]['success']).to eq(true)
      end

      it "Verify 'Signed Up' status is 'true'" do
        expect(res_login_2[:body]['subscription']['isSignedUp']).to eq(true)
      end
    end

    context '4. Login new account' do
      res_login_3 = nil

      it "Login account( email:#{new_email}, password:#{password})" do
        res_login_3 = login_sub_account(new_email, password)
      end

      it 'Verify user is able to login sucessful' do
        expect(res_login_3[:body]['success']).to eq(true)
      end

      it "Verify 'Signed Up' status is 'false'" do
        expect(res_login_3[:body]['subscription']['isSignedUp']).to eq(false)
      end
    end
  end

  context 'Service: Cancel membership' do
    res_cancel_mambership = nil

    it "Cancel membership( email: #{exist_email})" do
      res_cancel_mambership = cancel_membership exist_email, password
    end

    it 'Verify Cancel Membership successful' do
      expect(res_cancel_mambership['success']).to eq(true)
    end
  end

  context 'Service: Restart membership' do
    res_restart_mambership = nil

    it "Cancel membership( email: #{exist_email})" do
      res_restart_mambership = restart_membership exist_email, password
    end

    it 'Verify Cancel Membership successful' do
      expect(res_restart_mambership['success']).to eq(true)
    end
  end
end
