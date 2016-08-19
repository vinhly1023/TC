class DeviceManagement
  CONST_CALLER_ID = ENV['CONST_CALLER_ID']

  def initialize(env = 'QA')
    @service_info = CommonMethods.service_info :device_management, env
  end

  def update_profiles(session, type, device_serial, platform, slot, profile_name, child_id)
    CommonMethods.soap_call(
      @service_info[:endpoint],
      @service_info[:namespace],
      :update_profiles,
      "<caller-id>#{CONST_CALLER_ID}</caller-id>
      <session type='#{type}'>#{session}</session>
      <device serial='#{device_serial}' platform='#{platform}' product-id='0' auto-create='true'>
        <profile slot='#{slot}' name='#{profile_name}' points='0' rewards='0' weak-id='1' uploadable='true' claimed='true' dob='2014-06-09+07:00' grade='5' gender='male' child-id='#{child_id}' auto-create='true'/>
      </device>"
    )
  end

  def update_profiles_with_properties(data_hash)
    CommonMethods.soap_call(
      @service_info[:endpoint],
      @service_info[:namespace],
      :update_profiles,
      "<caller-id>#{CONST_CALLER_ID}</caller-id>
      <session type='#{data_hash[:type]}'>#{data_hash[:session]}</session>
      <device serial='#{data_hash[:dev_serial]}' platform='#{data_hash[:platform]}' product-id='0' auto-create='true'>
        <profile slot='#{data_hash[:slot]}' name='#{data_hash[:profile_name]}' points='0' rewards='0' weak-id='1' uploadable='true' claimed='true' dob='2014-06-09+07:00' grade='5' gender='male' child-id='#{data_hash[:child_id]}' auto-create='true'/>
        <properties><property key='pin' value='#{data_hash[:pin]}'/><property key='parentemail' value='#{data_hash[:username]}'/></properties>
      </device>"
    )
  end

  def list_nonimate_devices_info(session)
    list_devices_xml = CommonMethods.soap_call(
      @service_info[:endpoint],
      @service_info[:namespace],
      :list_nominated_devices,
      "<caller-id>#{CONST_CALLER_ID}</caller-id>
      <session type='service'>#{session}</session>"
    )

    return list_devices_xml if list_devices_xml[0] == 'error'
    device_info list_devices_xml
  end

  def unnominate_device(session, serial)
    response = CommonMethods.soap_call(
      @service_info[:endpoint],
      @service_info[:namespace],
      :unnominate_device,
      "<caller-id>#{CONST_CALLER_ID}</caller-id>
      <session type='service'>#{session}</session>
      <device serial='#{serial}'/>"
    )

    response
  end

  def device_info(list_devices_xml)
    device_info = []
    items = list_devices_xml.xpath('//device')
    items.map do |e|
      device_info.push(serial: e.at_xpath('@serial').content, platform: e.at_xpath('@platform').content, profiles: e.xpath('profile/@child-id').map(&:value))
    end

    device_info.select { |device| device[:profiles][0] != '0' }
  end

  def fetch_device(device_serial)
    CommonMethods.soap_call(
      @service_info[:endpoint],
      @service_info[:namespace],
      :fetch_device,
      "<caller-id>#{CONST_CALLER_ID}</caller-id>
      <device serial='#{device_serial}' product-id='' platform='' auto-create='false' pin=''>
        <properties>
        </properties>
      </device>"
    )
  end
end
