require File.expand_path('../../spec/spec_helper', __FILE__)
require 'customer_management'
require 'authentication'
require 'child_management'
require 'device_management'
require 'owner_management'
require 'device_log_upload'

def create_child(data)
  xml_register_child = ChildManagement.register_child_smoketest(data[:caller_id], data[:session], data[:customer_id], data[:child_name], data[:gender], data[:grade])
  child_info = ChildManagement.register_child_info xml_register_child

  it "Match content of [@name] - #{data[:child_name]}" do
    expect(child_info[:child_name]).to eq(data[:child_name])
  end

  it "Match content of [@gender] - #{data[:child_name]}" do
    expect(child_info[:gender]).to eq(data[:gender])
  end

  it "Match content of [@grade] - #{data[:child_name]}" do
    expect(child_info[:grade]).to eq(data[:grade])
  end

  child_info[:child_id]
end

def link_device_to_account(data)
  OwnerManagement.claim_device(data[:caller_id], data[:session], data[:customer_id], data[:device_serial], data[:platform], data[:slot], data[:child_name], '04444454')

  xml_list_nominated_devices_res = DeviceManagement.list_nominated_devices(data[:caller_id], data[:session], 'service')
  serial1 = xml_list_nominated_devices_res.xpath("//device[#{data[:index]}]").attr('serial').text
  platform1 = xml_list_nominated_devices_res.xpath("//device[#{data[:index]}]").attr('platform').text

  it "Match content of [@serial] - #{data[:child_name]}" do
    expect(serial1).to eq(data[:device_serial])
  end

  it "Match content of [@platform] - #{data[:child_name]}" do
    expect(platform1).to eq(data[:platform])
  end
end

def upload_device_log_and_game_log(caller_id, device_serial, child_id, filename, content_path)
  soap_fault1 = soap_fault2 = nil

  before :all do
    xml_upload_device = DeviceLogUpload.upload_device_log(caller_id, 'Jewel_Train_2.log', '0', device_serial, '2013-11-11T00:00:00', 'jeweltrain2.bin')
    soap_fault1 = xml_upload_device.xpath('//faultcode').count

    xml_upload_game = DeviceLogUpload.upload_game_log(caller_id, child_id, '2013-11-11T00:00:00', filename, content_path)
    soap_fault2 = xml_upload_game.xpath('//faultcode').count
  end

  it 'Verify Device Log Upload calls successfully' do
    expect(soap_fault1).to eq(0)
  end

  it 'Verify Device Content Upload calls successfully' do
    expect(soap_fault2).to eq(0)
  end
end

def fetch_and_verify_child_info(data, child_id)
  child_info = nil

  before :all do
    xml_fetch_child_rio = ChildManagement.fetch_child(data[:caller_id], data[:session], child_id)
    child_info = ChildManagement.fetch_child_info xml_fetch_child_rio
  end

  it "Match content of [@id] - #{data[:child_name]}" do
    expect(child_info[:child_id]).to eq(child_id)
  end

  it "Match content of [@name] - #{data[:child_name]}" do
    expect(child_info[:child_name]).to eq(data[:child_name])
  end

  it "Check for existence of [@gender] - #{data[:child_name]}" do
    expect(child_info[:gender]).to eq(data[:gender])
  end

  it "Match content of [@grade] - #{data[:child_name]}" do
    expect(child_info[:grade]).to eq(data[:grade])
  end

  it "Match content of [@locale] - #{data[:child_name]}" do
    expect(child_info[:locale]).to eq('en_US')
  end
end

def upload_logs(data, device_name)
  profile_content = package_id = 'SCPL-001300010001055B-20090325T130552800.lfp'

  DeviceLogUpload.upload_device_log(data[:caller_id], 'Jewel_Train_2.log', '0', data[:device_serial], '2013-11-11T00:00:00', 'jeweltrain2.bin')
  DeviceLogUpload.upload_game_log(data[:caller_id], data[:child_id], '2013-11-11T00:00:00', data[:file_name], data[:content_path])

  xml_fetch_upload = ChildManagement.fetch_child_upload_history(data[:caller_id], 'service', data[:session], data[:child_id])
  device_log = xml_fetch_upload.xpath('//device-log').count

  xml_upload_content = DeviceProfileContent.upload_content_wo_handle_exception data[:caller_id], data[:session], data[:device_serial], data[:slot], package_id, profile_content

  it "Check for existence of [device-log] - #{device_name}" do
    expect(device_log).not_to eq(0)
  end

  it "Verify 'uploadContent' - #{device_name} - calls successfully status code 200'" do
    expect(xml_upload_content.http.code).to eq(200)
  end
end
