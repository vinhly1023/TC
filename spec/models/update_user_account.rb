require 'spec_helper'

class UserUnitTest
  describe 'Update User Account' do
    # Set variable
    first_name = 'ltrc'
    last_name = 'vn'
    email = "ltrc_vn_test_#{SecureRandom.hex(5)}@testcentral.test"
    password = SecureRandom.hex(5)
    first_name_updated = 'ltrc_updated'
    last_name_updated = 'ltrc_updated'
    email_updated = "ltrc_vn_test_updated_#{SecureRandom.hex(5)}@testcentral.test"
    password_updated = SecureRandom.hex(5)
    user_id = nil
    acc_info = nil
    user = nil

    context 'Pre-condition - create user' do
      before :all do
        user = User.new(first_name: first_name, last_name: last_name, email: email, password: password, is_active: 1)
        user.create_user(3)
        acc_info = User.user_info_by_email(email)
        user_id = acc_info[:id]
      end

      it 'Verify that account is added to DB successfully' do
        expect(user_id).to_not eq(nil)
      end

      it 'Verify user information in UserRoleMap table' do
        expect(acc_info[:role_id]).to eq(3)
      end
    end

    context 'TC01 - Test update first_name' do
      it 'Update first_name user' do
        user_data = { first_name: first_name_updated, last_name: last_name, email: email_updated, password: password, is_active: 1 }
        user.update_user(user_data, 3)
        expect(User.user_info_by_id(user_id)[:first_name]).to eq(first_name_updated)
      end
    end

    context 'TC02 - Test update last_name' do
      it 'Update last_name user' do
        user_data = { first_name: first_name_updated, last_name: last_name_updated, email: email_updated, password: password, is_active: 1 }
        user.update_user(user_data, 3)
        expect(User.user_info_by_id(user_id)[:last_name]).to eq(last_name_updated)
      end
    end

    context 'TC03 - Test update password' do
      it 'Update password user' do
        pass_before = user[:password]
        user_data = { first_name: first_name_updated, last_name: last_name_updated, email: email_updated, password: password_updated, is_active: 1 }
        user.update_user(user_data, 3)
        expect(User.user_info_by_id(user_id)[:password]).to_not eq(pass_before)
      end
    end

    context 'TC04 - Test update role' do
      it 'Update role from QA to Power' do
        user_data = { first_name: first_name_updated, last_name: last_name_updated, email: email_updated, password: password_updated, is_active: 1 }
        user.update_user(user_data, 2)
        expect(UserRoleMap.find_by(user_id: user_id).role_id).to eq(2)
      end

      it 'Update role from Power to Admin' do
        user_data = { first_name: first_name_updated, last_name: last_name_updated, email: email_updated, password: password_updated, is_active: 1 }
        user.update_user(user_data, 1)
        expect(UserRoleMap.find_by(user_id: user_id).role_id).to eq(1)
      end

      it 'Update role from Admin to QA' do
        user_data = { first_name: first_name_updated, last_name: last_name_updated, email: email_updated, password: password_updated, is_active: 1 }
        user.update_user(user_data, 3)
        expect(UserRoleMap.find_by(user_id: user_id).role_id).to eq(3)
      end
    end

    context 'TC05 - Test update active' do
      it 'Update from activated to none-active' do
        user_data = { first_name: first_name_updated, last_name: last_name_updated, email: email_updated, password: password_updated, is_active: 0 }
        user.update_user(user_data, 3)
        expect(User.user_info_by_id(user_id)[:is_active]).to eq(false)
      end

      it 'Update from none-active to activated' do
        user_data = { first_name: first_name_updated, last_name: last_name_updated, email: email_updated, password: password_updated, is_active: 1 }
        user.update_user(user_data, 3)
        expect(User.user_info_by_id(user_id)[:is_active]).to eq(true)
      end
    end

    context 'TC06 - Test update mix fields' do
      it 'Update mix fields' do
        user_data = { first_name: first_name, last_name: last_name, email: email_updated, password: password, is_active: 1 }
        user.update_user(user_data, 3)
        expect(User.user_info_by_id(user_id)).to eq(
          id: user_id,
          first_name: first_name,
          last_name: last_name,
          email: email,
          is_active: true,
          full_name: "#{first_name} #{last_name}"
        )
      end
    end

    after :all do
      User.find(user_id).destroy
      UserRoleMap.find_by(user_id: user_id).destroy
    end
  end
end
