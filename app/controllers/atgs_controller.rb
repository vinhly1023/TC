class AtgsController < ApplicationController
  # get default data in last record in atg_configuration table
  def atg_configuration
    atg_data = AtgConfiguration.atg_configuration_data

    @empty_acc = atg_data[:ac_account][:empty_acc]
    @credit_acc = atg_data[:ac_account][:credit_acc]
    @balance_acc = atg_data[:ac_account][:balance_acc]
    @credit_balance_acc = atg_data[:ac_account][:credit_balance_acc]

    # Load LeapFrog account info
    @dev_acc = atg_data[:leapfrog_account][:dev_acc]
    @dev2_acc = atg_data[:leapfrog_account][:dev2_acc]
    @staging_acc = atg_data[:leapfrog_account][:staging_acc]
    @uat_acc = atg_data[:leapfrog_account][:uat_acc]
    @uat2_acc = atg_data[:leapfrog_account][:uat2_acc]
    @preview_acc = atg_data[:leapfrog_account][:preview_acc]
    @prod_acc = atg_data[:leapfrog_account][:prod_acc]

    # Load PayPal account info
    @p_us_acc = atg_data[:paypal_account][:p_us_acc]
    @p_ca_acc = atg_data[:paypal_account][:p_ca_acc]
    @p_uk_acc = atg_data[:paypal_account][:p_uk_acc]
    @p_ie_acc = atg_data[:paypal_account][:p_ie_acc]
    @p_au_acc = atg_data[:paypal_account][:p_au_acc]
    @p_row_acc = atg_data[:paypal_account][:p_row_acc]

    # Load Vindicia Account info
    @vin_username = atg_data[:vin_acc][:vin_username]
    @vin_password = atg_data[:vin_acc][:vin_password]
  end

  def update_atg_data
    ac_account = {
      empty_acc: [params[:empty_email], params[:empty_pass]],
      credit_acc: [params[:credit_email], params[:credit_pass]],
      balance_acc: [params[:balance_email], params[:balance_pass]],
      credit_balance_acc: [params[:credit_balance_email], params[:credit_balance_pass]]
    }

    leapfrog_account = {
      dev_acc: params[:dev_acc],
      dev2_acc: params[:dev2_acc],
      staging_acc: params[:staging_acc],
      uat_acc: params[:uat_acc],
      uat2_acc: params[:uat2_acc],
      preview_acc: params[:preview_acc],
      prod_acc: params[:prod_acc]
    }

    paypal_account = {
      p_us_acc: [params[:p_email_us], params[:p_password_us]],
      p_ca_acc: [params[:p_email_ca], params[:p_password_ca]],
      p_uk_acc: [params[:p_email_uk], params[:p_password_uk]],
      p_ie_acc: [params[:p_email_ie], params[:p_password_ie]],
      p_au_acc: [params[:p_email_au], params[:p_password_au]],
      p_row_acc: [params[:p_email_row], params[:p_password_row]]
    }

    vin_acc = {
      vin_username: params[:vin_username],
      vin_password: params[:vin_password]
    }

    atg_data = {
      ac_account: ac_account,
      leapfrog_account: leapfrog_account,
      paypal_account: paypal_account,
      vin_acc: vin_acc
    }.to_json

    # update input to xml file
    msg = AtgConfiguration.update_atg_data atg_data
    msg ? (flash[:success] = 'Your ATG data is updated successfully!') : (flash[:error] = msg)

    redirect_to action: 'atg_configuration'
  end

  # get data and process then return to view using ajax
  def atg_tracking_data
    env = params[:env].downcase # uat or uat2
    loc = params[:loc].downcase # US or CA

    if env.blank? || loc.blank?
      render plain: ['']
    else
      render plain: AtgTracking.where("email like '%atg_#{env}_#{locale}%'").order(updated_at: :desc).pluck(:email, :address1)
    end
  end

  # create new test suite from dialog ajax call
  def create_ts
    tsname = params[:tsname] # Smoke test account management
    tcs = params[:tcs].chomp(',').split(',') # 'value1,value2,..,' => array

    connection = ActiveRecord::Base.connection
    inserts = []
    ts_id = -1

    ActiveRecord::Base.transaction do
      # get silo id
      silo = Silo.find_by name: 'ATG'

      # get maximum order
      max_order_suite = Suite.maximum(:order) + 1
      max_order_suitecsm = CaseSuiteMap.maximum(:order) + 1

      # insert into suites
      suite = Suite.create(name: tsname, silo_id: silo.id, description: '', order: max_order_suite)
      suite.create_activity key: 'suite.create', owner: User.current_user
      ts_id = suite.id

      # insert into suite_maps
      SuiteMap.create(parent_suite_id: ts_id, child_suite_id: ts_id)

      # insert into case_suite_maps
      tcs.each do |tc_id|
        inserts.push "(#{suite.id}, #{tc_id}, #{max_order_suitecsm})"
        max_order_suitecsm += 1
      end

      sql = "INSERT INTO case_suite_maps (`suite_id`, `case_id`, `order`) VALUES #{inserts.join(', ')}"
      connection.execute sql
    end

    render plain: [ts_id]
  end

  def upload_code
    pin_file = params[:pin_file]
    pin_type = params[:pin_type]
    env = params[:env]

    @message = Pin.upload_pin_file(pin_file.path, env, pin_type) if pin_file
    @available_pins_html = Atg.available_pins
    @pin_type = Atg.pin_types
  end

  def clean_pins
    Atg.clean_all_pins
    render html: Atg.available_pins.html_safe
  end

  def first_parent_level_tss
    render plain: Atg.new.get_test_suites(true)
  end

  def parent_suite_id
    render plain: Atg.new.get_test_suite_parent(params[:ts_id])
  end

  def release_date
    language = params[:language]
    html_str = ''

    release_opts = Atg.release_date language
    release_opts.each do |key, value|
      html_str += <<-INTERPOLATED_HEREDOC
        <li><label>
          <input type="checkbox" value="#{key}">
          <span>#{key} - Total: #{value} app#{'s' if value.to_i > 1}</span>
        </label></li>
      INTERPOLATED_HEREDOC
    end

    render plain: html_str.html_safe
  rescue => e
    Rails.logger.error "Error while loading release dates #{ModelCommon.full_exception_error e}"
  end

  def upload_server_url
    server_url_file = params[:server_url_file]
    @message = AtgServerUrl.atg_upload_server_url server_url_file.path if server_url_file
    @server_url_data = AtgServerUrl.atg_server_url_data
  end

  def upload_com_server
    com_server_file = params[:com_server_file]
    @message = AtgComServer.atg_upload_com_server com_server_file.path if com_server_file
    @com_server_data = AtgComServer.atg_com_server_data
  end

  def upload_promotion_code
    env = params[:env]
    promotion_file = params[:promotion_file]
    @message = AtgPromotion.atg_upload_promotion_code(env, promotion_file.path) if promotion_file
    @promotion_data = AtgPromotion.atg_promotion_data
  end

  private

  def atg_params
    params.permit(:env, :user_email, :testsuite, :release_date)
  end
end
