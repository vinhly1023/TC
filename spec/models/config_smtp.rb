require 'spec_helper'
require 'read_config_xml'

class RailsAppConfigUnitTest
  describe 'Admin Configuration: SMTP Setting' do
    # Set variable
    smtp_info = nil
    config_file_xml = ReadXML.new
    rails_app_config = RailsAppConfig.new config_file_xml.config_file

    before :all do
      smtp_info = config_file_xml.smtp_info
      @address = smtp_info[:address]
      @port = smtp_info[:port]
      @domain = smtp_info[:domain]
      @username = smtp_info[:username]
      @password = smtp_info[:password]
      @attach_type = smtp_info[:attachment_type]
    end

    context 'TC01 - Update SMTP address' do
      it 'Update SMTP address' do
        rails_app_config.update_smtp_settings(
          address: 'smtp1.gmail.com',
          port: @port,
          domain: @domain,
          username: @username,
          password: @password,
          attachment_type: @attach_type
        )

        expect(config_file_xml.smtp_info[:address]).to eq('smtp1.gmail.com')
      end
    end

    context 'TC02 - Update SMTP port' do
      it 'Update SMTP port' do
        rails_app_config.update_smtp_settings(
          address: 'smtp1.gmail.com',
          port: '588',
          domain: @domain,
          username: @username,
          password: @password,
          attachment_type: @attach_type
        )

        expect(config_file_xml.smtp_info[:port]).to eq('588')
      end
    end

    context 'TC03 - Update SMTP domain' do
      it 'Update SMTP domain' do
        rails_app_config.update_smtp_settings(
          address: 'smtp1.gmail.com',
          port: @port,
          domain: 'testcentral1.com',
          username: @username,
          password: @password,
          attachment_type: @attach_type
        )

        expect(config_file_xml.smtp_info[:domain]).to eq('testcentral1.com')
      end
    end

    context 'TC04 - Update SMTP username' do
      it 'Update SMTP username' do
        rails_app_config.update_smtp_settings(
          address: 'smtp1.gmail.com',
          port: @port,
          domain: @domain,
          username: 'lflgautomation@gmail1.com',
          password: @password,
          attachment_type: @attach_type
        )

        expect(config_file_xml.smtp_info[:username]).to eq('lflgautomation@gmail1.com')
      end
    end

    context 'TC05 - Update SMTP password' do
      it 'Update smtp password' do
        rails_app_config.update_smtp_settings(
          address: 'smtp1.gmail.com',
          port: @port,
          domain: @domain,
          username: @username,
          password: '1234567',
          attachment_type: @attach_type
        )

        expect(config_file_xml.smtp_info[:password]).to eq('1234567')
      end
    end

    context 'TC06 - Update SMTP attach type' do
      it 'Update SMTP attach type - ZIP' do
        rails_app_config.update_smtp_settings(
          address: 'smtp1.gmail.com',
          port: @port,
          domain: @domain,
          username: @username,
          password: @password,
          attachment_type: 'ZIP'
        )

        expect(config_file_xml.smtp_info[:attachment_type]).to eq('ZIP')
      end

      it 'Update SMTP attach type - HTML' do
        rails_app_config.update_smtp_settings(
          address: 'smtp1.gmail.com',
          port: @port,
          domain: @domain,
          username: @username,
          password: @password,
          attachment_type: 'HTML'
        )

        expect(config_file_xml.smtp_info[:attachment_type]).to eq('HTML')
      end
    end

    context 'TC07 - Update SMTP mix fields' do
      before :all do
        rails_app_config.update_smtp_settings(
          address: 'smtp.gmail.com',
          port: '587',
          domain: 'testcentral.com',
          username: 'lflgautomation@gmail.com',
          password: '123456',
          attachment_type: 'NONE'
        )

        smtp_info = config_file_xml.smtp_info
      end

      it 'Verify SMTP info updates correctly' do
        expect(smtp_info).to eq(
          address: 'smtp.gmail.com',
          port: '587',
          domain: 'testcentral.com',
          username: 'lflgautomation@gmail.com',
          password: '123456',
          attachment_type: 'NONE'
        )
      end
    end

    after :all do
      config_file_xml.delete_config_file
    end
  end
end
