require 'spec_helper'

class UserUnitTest
  describe 'Create new User' do
    # Set variable
    first_name = 'ltrc'
    last_name = 'vn'
    qa_acc = "ltrc_qa_test_#{SecureRandom.hex(5)}@leapfrog.test"
    power_acc = "ltrc_power_test_#{SecureRandom.hex(5)}@leapfrog.test"
    admin_acc = "ltrc_admin_test_#{SecureRandom.hex(5)}@leapfrog.test"
    password = SecureRandom.hex(5)
    acc_info = nil

    context 'TC01 - Create new QA account - active' do
      before :all do
        user = User.new(first_name: first_name, last_name: last_name, email: qa_acc, password: password, is_active: 1)
        user.create_user(3)
        acc_info = User.user_info_by_email(qa_acc)
      end

      it 'Verify that account is added to DB successfully' do
        expect(acc_info[:id]).to_not eq(nil)
      end

      it 'Verify that account is added to DB with correct First-name' do
        expect(acc_info[:first_name]).to eq(first_name)
      end

      it 'Verify that account is added to DB with correct Last-name' do
        expect(acc_info[:last_name]).to eq(last_name)
      end

      it 'Verify that account is added to DB with correct Email' do
        expect(acc_info[:email]).to eq(qa_acc)
      end

      it "Verify that account is added to DB with 'is_active' = true" do
        expect(acc_info[:is_active]).to eq(true)
      end

      it 'Verify user information in UserRoleMap table' do
        expect(acc_info[:role_id]).to eq(3)
      end

      after :all do
        User.find_by(id: acc_info[:id]).destroy
        UserRoleMap.find_by(user_id: acc_info[:id]).destroy
      end
    end

    context 'TC02 - Create new POWER account - active' do
      before :all do
        user = User.new(first_name: first_name, last_name: last_name, email: power_acc, password: password, is_active: 1)
        user.create_user(2)
        acc_info = User.user_info_by_email(power_acc)
      end

      it 'Verify that account is added to DB successfully' do
        expect(acc_info[:id]).to_not eq(nil)
      end

      it 'Verify that account is added to DB with correct First-name' do
        expect(acc_info[:first_name]).to eq(first_name)
      end

      it 'Verify that account is added to DB with correct Last-name' do
        expect(acc_info[:last_name]).to eq(last_name)
      end

      it 'Verify that account is added to DB with correct Email' do
        expect(acc_info[:email]).to eq(power_acc)
      end

      it "Verify that account is added to DB with 'is_active' = true" do
        expect(acc_info[:is_active]).to eq(true)
      end

      it 'Verify user information in UserRoleMap table' do
        expect(acc_info[:role_id]).to eq(2)
      end

      after :all do
        User.find_by(id: acc_info[:id]).destroy
        UserRoleMap.find_by(user_id: acc_info[:id]).destroy
      end
    end

    context 'TC03 - Create new ADMIN account - active' do
      before :all do
        user = User.new(first_name: first_name, last_name: last_name, email: admin_acc, password: password, is_active: 1)
        user.create_user(1)
        acc_info = User.user_info_by_email(admin_acc)
      end

      it 'Verify that account is added to DB successfully' do
        expect(acc_info[:id]).to_not eq(nil)
      end

      it 'Verify that account is added to DB with correct First-name' do
        expect(acc_info[:first_name]).to eq(first_name)
      end

      it 'Verify that account is added to DB with correct Last-name' do
        expect(acc_info[:last_name]).to eq(last_name)
      end

      it 'Verify that account is added to DB with correct Email' do
        expect(acc_info[:email]).to eq(admin_acc)
      end

      it "Verify that account is added to DB with 'is_active' = true" do
        expect(acc_info[:is_active]).to eq(true)
      end

      it 'Verify user information in UserRoleMap table' do
        expect(acc_info[:role_id]).to eq(1)
      end

      after :all do
        User.find_by(id: acc_info[:id]).destroy
        UserRoleMap.find_by(user_id: acc_info[:id]).destroy
      end
    end

    context 'TC04 - Create new QA account - non-active' do
      before :all do
        user = User.new(first_name: first_name, last_name: last_name, email: qa_acc, password: password, is_active: 0)
        user.create_user(3)
        acc_info = User.user_info_by_email(qa_acc)
      end

      it 'Verify that account is added to DB successfully' do
        expect(acc_info[:id]).to_not eq(nil)
      end

      it 'Verify that account is added to DB with correct First-name' do
        expect(acc_info[:first_name]).to eq(first_name)
      end

      it 'Verify that account is added to DB with correct Last-name' do
        expect(acc_info[:last_name]).to eq(last_name)
      end

      it 'Verify that account is added to DB with correct Email' do
        expect(acc_info[:email]).to eq(qa_acc)
      end

      it "Verify that account is added to DB with 'is_active' = false" do
        expect(acc_info[:is_active]).to eq(false)
      end

      it 'Verify user information in UserRoleMap table' do
        expect(acc_info[:role_id]).to eq(3)
      end

      after :all do
        User.find_by(id: acc_info[:id]).destroy
        UserRoleMap.find_by(user_id: acc_info[:id]).destroy
      end
    end

    context 'TC05 - Create new POWER account - non-active' do
      before :all do
        user = User.new(first_name: first_name, last_name: last_name, email: power_acc, password: password, is_active: 0)
        user.create_user(2)
        acc_info = User.user_info_by_email(power_acc)
      end

      it 'Verify that account is added to DB successfully' do
        expect(acc_info[:id]).to_not eq(nil)
      end

      it 'Verify that account is added to DB with correct First-name' do
        expect(acc_info[:first_name]).to eq(first_name)
      end

      it 'Verify that account is added to DB with correct Last-name' do
        expect(acc_info[:last_name]).to eq(last_name)
      end

      it 'Verify that account is added to DB with correct Email' do
        expect(acc_info[:email]).to eq(power_acc)
      end

      it "Verify that account is added to DB with 'is_active' = false" do
        expect(acc_info[:is_active]).to eq(false)
      end

      it 'Verify user information in UserRoleMap table' do
        expect(acc_info[:role_id]).to eq(2)
      end

      after :all do
        User.find_by(id: acc_info[:id]).destroy
        UserRoleMap.find_by(user_id: acc_info[:id]).destroy
      end
    end

    context 'TC06 - Create new ADMIN account - non-active' do
      before :all do
        user = User.new(first_name: first_name, last_name: last_name, email: admin_acc, password: password, is_active: 0)
        user.create_user(1)
        acc_info = User.user_info_by_email(admin_acc)
      end

      it 'Verify that account is added to DB successfully' do
        expect(acc_info[:id]).to_not eq(nil)
      end

      it 'Verify that account is added to DB with correct First-name' do
        expect(acc_info[:first_name]).to eq(first_name)
      end

      it 'Verify that account is added to DB with correct Last-name' do
        expect(acc_info[:last_name]).to eq(last_name)
      end

      it 'Verify that account is added to DB with correct Email' do
        expect(acc_info[:email]).to eq(admin_acc)
      end

      it "Verify that account is added to DB with 'is_active' = false" do
        expect(acc_info[:is_active]).to eq(false)
      end

      it 'Verify user information in UserRoleMap table' do
        expect(acc_info[:role_id]).to eq(1)
      end

      after :all do
        User.find_by(id: acc_info[:id]).destroy
        UserRoleMap.find_by(user_id: acc_info[:id]).destroy
      end
    end
  end
end
