require File.expand_path('../../spec_helper', __FILE__)
require 'pages/mail/mail_home_page'
require 'pages/mail/mail_detail_page'

=begin
Verify that an email notification is received in a real service when creating or resetting account
=end

# initial variables
start_browser
mail_home_page = HomePageMail.new
mail_detail_page = nil
caller_id = Misc::CONST_CALLER_ID
password = Misc::CONST_PASSWORD
e_success_create_txt = 'Welcome to LeapFrog'
e_success_reset_txt = 'How to reset your LeapFrog password'
locales = ['en_US', 'en_CA', 'en_IE', 'en_GB', 'en_AU', 'en_OE', 'fr_FR', 'fr_CA', 'fr_OF']

feature "TS23 - Email notification checking for account creating and resetting - ENV = '#{Misc::CONST_ENV}'", js: true do
  locales.each do |locale|
    email = LFCommon.generate_real_email locale
    username = screen_name = email

    context "Check on locale #{locale}" do
      context 'Check created email in a real service' do
        cus_id = nil

        scenario "1. Register new account (Email: #{email} - Password: #{password})" do
          res = CustomerManagement.register_customer(caller_id, screen_name, email, username, password, locale)
          cus_id = CustomerManagement.get_customer_info(res)[:id]
        end

        scenario '2. Verify register is successful' do
          expect(cus_id).not_to eq('')
        end

        scenario '3. Go to \'Guerrillamail\' mail box' do
          mail_detail_page = mail_home_page.go_to_mail_detail(email, 1)
          pending "***3. Go to 'Guerrillamail' mail box (URL: #{mail_detail_page.current_url})"
        end

        scenario "4. Verify 'Check account #{email} is received' in Guerrillamail" do
          email_info = mail_detail_page.email_info
          expect(email_info[:subject]).to include("To: #{email.split('@')[0]}")
        end

        scenario "5. Verify 'Check '#{e_success_create_txt}' message' in account #{email}" do
          e_success_create_txt = 'Bienvenue sur LeapFrog' if locale.include?('fr')
          email_info = mail_detail_page.email_info
          expect(email_info[:success_create_message]).to eq(e_success_create_txt)
        end
      end

      context 'Check Reset Password Email in a real service' do
        scenario '1. Reset password' do
          xml_response = CustomerManagement.reset_password(caller_id, username)
          expect(xml_response.xpath('//resetPasswordResponse').text).not_to eq(nil)
        end

        scenario '2. Go to \'Guerrillamail\' mail box' do
          mail_detail_page = mail_home_page.go_to_mail_detail(email, 2)
          pending "***2. Go to 'Guerrillamail' mail box (URL: #{mail_detail_page.current_url})"
        end

        scenario "3. Verify 'Check reset account #{email} is received' in Guerrillamail" do
          email_info = mail_detail_page.email_info
          expect(email_info[:subject]).to include("To: #{email.split('@')[0]}")
        end

        scenario "4. Verify 'Check '#{e_success_reset_txt}' message' in account #{email}" do
          e_success_reset_txt = 'Comment r&eacute;initialiser votre mot de passe LeapFrog' if locale.include?('fr')
          email_info = mail_detail_page.email_info
          expect(email_info[:success_reset_message]).to eq(e_success_reset_txt)
        end
      end
    end
  end
end
