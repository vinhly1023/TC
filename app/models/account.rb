class Account
  def self.do_oobe_flow(env, auto_link, username, password, platform, child_id = nil, dev_serial = nil)
    platforms_wireless_devices = ['leapup', 'leappad3explorer', 'leappad3', 'leappadplatinum', 'android1']

    customer_management_service = CustomerManagement.new env
    authentication_service = Authentication.new env
    owner_management_service = OwnerManagement.new env
    device_management_service = DeviceManagement.new env
    device_profile_management = DeviceProfileManagement.new env

    # Get customer ID and session
    customer_id = customer_management_service.get_customer_id username
    session = authentication_service.get_service_session(username, password)
    profile_name = 'AutoProfile'

    if auto_link
      # auto-generate device serial and register child
      dev_serial = profile_name = "#{platform}#{Time.now.strftime('%Y%m%d%H%M%S')}"
      child_id = register_child_id(env, session, customer_id, profile_name)
    else
      # Get platform from the entered device_serial
      fetch_device_xml = device_management_service.fetch_device dev_serial
      platform = fetch_device_xml.at_xpath('//device/@platform').to_s
      child_id = register_child_id(env, session, customer_id, profile_name) if child_id.empty?
    end

    # claim device
    owner_management_service.claim_device(session, customer_id, dev_serial, platform, 1, profile_name, child_id, Time.now, '5', 'male')

    if platforms_wireless_devices.include? platform
      data_hash = { username: username, session: session, type: 'service', dev_serial: dev_serial, platform: platform, slot: 1, profile_name: profile_name, child_id: child_id, pin: '1111' }
      device_management_service.update_profiles_with_properties data_hash
    else
      device_management_service.update_profiles(session, 'service', dev_serial, platform, 1, profile_name, child_id)
    end

    # assign profile
    device_profile_management.assign_device_profile(customer_id, dev_serial, platform, 1, profile_name, child_id)
  end

  def self.register_child_id(env, session, customer_id, profile_name)
    children_management_service = ChildManagement.new env
    child_res = children_management_service.register_child(session, customer_id, profile_name)
    child_res.at_xpath('//child/@id').to_s
  end

  def self.remove_all_license(session, customer_id, env)
    license_management = LicenseManagement.new env
    account_license = license_management.get_all_account_licenses(session, customer_id)
    account_license.each { |id| license_management.revoke_license($session, id) }

    Parallel.each(account_license, in_threads: 10) do |license|
      license_management.revoke_license($session, license[:license_id])
    end
  end

  def self.unnominate_all_device(session, env)
    device_arr = []
    device_management = DeviceManagement.new env
    list_nonimate_devices = device_management.list_nonimate_devices_info session

    list_nonimate_devices.each do |dv|
      serial = dv[:serial]
      platform = dv[:platform]
      next if device_management.unnominate_device(session, serial)[0] == 'error'
      device_arr.push(platform: platform, serial_number: serial)
    end

    device_arr
  end
end
