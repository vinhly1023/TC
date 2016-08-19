$env = nil
$session = nil

class AccountsController < ApplicationController
  PLATFORMS_CONST = {
    'Jump' => 'leapband',
    'LeapTV' => 'leapup',
    'LeapPad3' => 'leappad3explorer',
    'LeapPad Ultra' => 'leappad3',
    'LeapPad2' => 'leappad2',
    'LeapPad1' => 'leappad',
    'Leapster Explorer' => 'leapster2',
    'LeapsterGS Explorer' => 'explorer2',
    'LeapReader' => 'leapreader',
    'Bogota' => 'leappadplatinum',
    'Narnia' => 'android1'
  }

  def clear_account
    return flash.clear unless params[:commit]

    env = params[:env]
    return flash.now[:error] = 'You don\'t have permission to do this action.' if env != 'QA' && session[:user_role] == 3

    email = params[:email]
    password = params[:password]
    authentication = Authentication.new env
    customer_management = CustomerManagement.new env
    license_management = LicenseManagement.new env
    session = authentication.get_service_session(email, password)

    return flash.now[:error] = 'The email/password is not correct' if session[0] == 'error'

    # Get customer id by username
    customer_id = customer_management.get_customer_id(email)
    device_arr = []

    # If 'Remove license only' checkbox is un-checked -> Clear devices,
    # Else-> Just remove licences
    if params[:is_active]
      Account.remove_all_license session, customer_id, env
      device_arr = 'Remove license only'
    else
      device_arr = Account.unnominate_all_device session, env
    end

    # fetchRestrictedLicenses
    fetch_restricted_licenses_res = license_management.fetch_restricted_licenses(session, customer_id)

    # revokeLicense for each license
    license_arr = license_management.get_revoked_license(fetch_restricted_licenses_res, session)

    @account = {
      email: email,
      password: password,
      device: device_arr,
      license: license_arr,
      env: env
    }

    render 'show'
  rescue => e
    flash.now[:error] = "Error while clearing account: #{e.message}"
    render 'clear_account'
  end

  def link_devices
    @all_platforms = PLATFORMS_CONST.to_a.unshift(['All', 'all'])
  end

  def unlink_devices
    device_management = DeviceManagement.new $env
    devices = params[:devices] || []
    success = []

    devices.each { |d| success.push device_management.unnominate_device($session, d) }

    if success.select { |e| e[0] == 'error' }.empty?
      render json: ['Successfully']
    else
      render json: "Error for devices: #{success}. Please check the input/network and re-do", status: 400
    end
  rescue => e
    render json: e.message, status: 400
  end

  def process_linking_devices
    auto_link = params[:atg_ld_autolink]
    env = params[:atg_ld_env]
    email = params[:atg_ld_email]
    password = params[:atg_ld_password]
    platform = params[:atg_ld_platform]

    unless auto_link == 'true'
      Account.do_oobe_flow(env, false, email, password, platform, params[:atg_ld_children], params[:atg_ld_deviceserial])
      return render json: ['success']
    end

    if platform == 'all'
      PLATFORMS_CONST.each_value { |v| Account.do_oobe_flow(env, true, email, password, v) }
    else
      Account.do_oobe_flow(env, true, email, password, platform)
    end

    render json: ['success']
  rescue
    render json: 'Username/password or Network may have problems', status: 400
  end

  def fetch_customer
    $session = nil
    @env = $env = params[:env]
    @editable = false
    customer_management = CustomerManagement.new $env
    authentication = Authentication.new $env
    email = valid_email(params[:user_email])

    return render 'fetch_customer' unless email

    flash.now[:error] = 'The email\'s format should be: example@abc.com' unless email
    password = params[:user_password].to_s

    if password.empty?
      case params[:env]
      when 'QA'
        $session = ENV['CONST_SESSION_QA']
      when 'STAGING'
        $session = ENV['CONST_SESSION_STAGING']
      else # 'PROD'
        $session = ENV['CONST_SESSION_PROD']
      end
    else
      $session = authentication.get_service_session(email, password)

      if $session[0] == 'error'
        flash.now[:error] = $session[1]
        return render 'fetch_customer'
      else
        @editable = true
        flash.clear
      end
    end

    customer_id = customer_management.get_customer_id email

    if customer_id[0] == 'error' || customer_id.blank?
      flash.now[:error] = 'The email address or password you entered is incorrect. Please try again.'
      render 'fetch_customer'
    else
      res = customer_management.fetch_customer customer_id
      @cus_info = Hash.from_xml(res.at_xpath('//customer').to_s)
      render 'fetch_customer'
    end
  rescue => e
    flash.now[:error] = e.message
    render 'fetch_customer'
  end

  def children
    return render json: [] unless $session
    customer_id = params[:cus_id]
    child_management = ChildManagement.new $env
    render json: child_management.list_children_info($session, customer_id)
  rescue => e
    render json: e.message, status: 400
  end

  def devices
    return render json: [] unless $session
    device_management = DeviceManagement.new $env
    render json: device_management.list_nonimate_devices_info($session)
  rescue => e
    render json: e.message, status: 400
  end

  def app_history
    return render json: [] unless $session
    customer_id = params[:cus_id]
    license_management = LicenseManagement.new $env
    package_management = PackageManagement.new $env
    device_management = DeviceManagement.new $env
    account_license = license_management.get_all_account_licenses($session, customer_id)

    # Get app_name by on SKU number
    Parallel.each(account_license, in_threads: 10) do |license|
      license[:app_name] = package_management.get_package_name(license[:sku])
    end

    devices = device_management.list_nonimate_devices_info($session)
    device_arr = package_management.get_device_licenses($session, devices)
    device_license = filter_device_license(device_arr)

    # Map the app information on device and account
    @apps = get_license_info(account_license, device_license)

    # Get the list of available license on Account
    @revoke_license = []
    account_license.each do |acc|
      @revoke_license.push([acc[:app_name], acc[:license_id]])
    end

    render json: { apps: @apps, revoke_license: @revoke_license }.to_json
  rescue => e
    render json: e.message, status: 400
  end

  def update_customer
    customer_management = CustomerManagement.new $env
    email = params[:email]
    firstname = params[:first_name]
    lastname = params[:last_name]
    middle = params[:middle_name]
    temp_alias = params[:alias]
    screen = params[:screen]
    locale = params[:locale]
    salutation = params[:salutation]
    cusid = params[:cus_id]
    username = params[:username]
    password = params[:password]
    password_hint = params[:password_hint]
    phone_msg = ''
    addr_msg = ''

    if params[:num_of_addr]
      num_of_addr = params[:num_of_addr].to_i
      (1..num_of_addr).each do |i|
        addr_msg << <<-INTERPOLATED_HEREDOC.strip_heredoc
          <address type=\'#{params[:"address_type#{i}"]}\' id=\'#{params[:"addr_id#{i}"]}\'>
            <street>#{params[:"street#{i}"]}</street>
              <region city=\'#{params[:"city#{i}"]}\' country=\'#{params[:"country#{i}"]}\' province=\'#{params[:"province#{i}"]}\' postal-code=\'#{params[:"postal#{i}"]}\'/>
          </address>
        INTERPOLATED_HEREDOC
      end
    else
      addr_msg = (<<-INTERPOLATED_HEREDOC.strip_heredoc
        <address type=\'#{params[:address_type]}\' id=\'#{params[:addr_id]}\'>
          <street>#{params[:street]}</street>
          <region city=\'#{params[:city]}\' country=\'#{params[:country]}\' province=\'#{params[:province]}\' postal-code=\'#{params[:postal]}\'/>
        </address>
      INTERPOLATED_HEREDOC
                 ) if params[:address_type] && params[:addr_id] && params[:street]
    end

    if params[:num_of_phones]
      num_of_phones = params[:num_of_phones].to_i
      (1..num_of_phones).each do |i|
        phone_msg << <<-INTERPOLATED_HEREDOC.strip_heredoc
          <phone type=\'#{params[:"phone_type#{i}"]}\' extension=\'#{params[:"ext#{i}"]}\' number=\'#{params[:"number#{i}"]}\'/>
        INTERPOLATED_HEREDOC
      end
    else
      phone_msg = (<<-INTERPOLATED_HEREDOC.strip_heredoc
        <phone type=\'#{params[:phone_type]}\' extension=\'#{params[:ext]}\' number=\'#{params[:number]}\'/>
      INTERPOLATED_HEREDOC
                  ) if params[:phone_type] && params[:ext] && params[:number]
    end

    # update customer
    customer_management.update_customer_full_info(cusid, firstname, lastname, middle, salutation, locale, temp_alias, screen, email, phone_msg, addr_msg, username, password, password_hint)

    render json: ['Successfully']
  rescue => e
    render json: e.message, status: 400
  end

  def revoke_license
    license_management = LicenseManagement.new $env
    license_ids = params[:revoke_licenses] || []
    success = []

    license_ids.each { |id| success.push license_management.revoke_license($session, id) }
    success.delete true

    if success == []
      render json: ['Revoke successfully']
    else
      render json: "Could not revoke for #{success}. Please check information/network and redo", status: 400
    end
  rescue => e
    render json: e.message, status: 400
  end

  def remove_license
    package_management = PackageManagement.new $env
    remove = package_management.remove_installation($session, params[:device_serial], params[:sku], params[:slot])

    if remove[0] == 'error'
      render json: remove[1], status: 400
    else
      render json: 'App is removed successfully'
    end
  rescue => e
    render json: e.message, status: 400
  end

  def report_installation
    package_management = PackageManagement.new $env
    install = package_management.report_installation($session, params[:device_serial], params[:sku], params[:license_id])

    if install[0] == 'error'
      render json: install[1], status: 400
    else
      render json: 'App is installed successfully'
    end
  rescue => e
    render json: e.message, status: 400
  end

  private

  def valid_email(email)
    email =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i ? email : nil
  end

  #
  # This method is used to map the app information on device and account
  # Include info: license_id, app_title, sku, type, grant_date, device_serial, status, slot, package_id
  #
  def get_license_info(account_license, device_license)
    account_license.map do |acc|
      {
        license_id: acc[:license_id],
        app_name: acc[:app_name],
        sku: acc[:sku],
        type: acc[:type],
        grant_date: acc[:grant_date],
        device_info: device_license.select { |license| license[:package_name] == acc[:app_name] }
      }
    end
  end

  #
  # Get status, package_name of app on device
  # If app is installed on device -> get slot that app installed
  #
  def filter_device_license(licenses_arr)
    duplicated_items = []

    (0..licenses_arr.length - 1).each do |i|
      (i + 1..licenses_arr.length - 1).each do |j|
        if licenses_arr[i][:device_serial] == licenses_arr[j][:device_serial] && licenses_arr[i][:package_name] == licenses_arr[j][:package_name]
          if licenses_arr[i][:status] == 'pending'
            licenses_arr[i][:status] = licenses_arr[j][:status]
            licenses_arr[i][:slot] = licenses_arr[j][:slot]

            duplicated_items.push(licenses_arr[j])
            break
          elsif licenses_arr[j][:status] == 'pending'
            licenses_arr[j][:status] = licenses_arr[i][:status]
            licenses_arr[j][:slot] = licenses_arr[i][:slot]

            duplicated_items.push(licenses_arr[i])
            break
          end
          next
        end
        next
      end
    end

    licenses_arr - duplicated_items
  end
end
