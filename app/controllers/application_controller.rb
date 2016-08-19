class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :reset_session
  before_filter :grant_permission, except: %w(sign_in about contact sign_up status sign_out)

  def grant_permission
    User.current_user = User.find_by(email: session[:user_email])
    return if session[:user_role] == 1

    guest_op_paths = ['/outpost/upload_result', '/outpost/upload_moas', '/outpost/platform_checker', '/outpost/promotion_code', '/run/index', '/run/delete']
    qa_op_paths = ['/outpost/outpost_config', '/outpost/upload_pin']
    guest_op_urls = []
    qa_op_urls = []

    Outpost.select(:silo).distinct.each do |x|
      guest_op_urls += guest_op_paths.collect { |e| "#{x.silo.downcase}#{e}" }
      qa_op_urls += qa_op_paths.collect { |e| "#{x.silo.downcase}#{e}" }
    end

    power_access_denied_list = ['users/create', 'users/logging', 'tc/run/index', 'tc/run/delete', 'tc/run/view_silo_group']
    qa_access_denied_list = power_access_denied_list + ['stations/index', 'rails_app_config/configuration', 'email_rollup/index', 'atgs/upload_server_url', 'atgs/upload_com_server', 'atgs/upload_promotion_code', 'atgs/atg_configuration', 'atgs/upload_code', 'atg_moas_importings/index'] + qa_op_urls
    guest_access_denied_list = qa_access_denied_list + ['scheduler/index', 'atg/run/index', 'atg/run/delete', 'ws/run/index', 'ws/run/delete', 'pins/pin_status', 'atg_content_platform_checker/index', 'users/help'] + guest_op_urls

    case session[:user_role]
    when 2 # PowerUser
      deny_access power_access_denied_list
    when 3 # QA
      deny_access qa_access_denied_list
    else
      deny_access(guest_access_denied_list, true)
    end
  end

  def deny_access(controls, is_guest = false)
    controller = params[:controller]
    action = params[:action]
    silo = params[:silo_name]
    type = params[:type]
    controller_action_path = controller + '/' + action

    if silo.blank?
      controller_action_path = (type + '/' + controller_action_path) unless type.blank?
      return unless controls.include? controller_action_path
    else
      return unless controls.include? silo.downcase + '/' + controller_action_path
    end

    if is_guest
      store_current_location
      flash.now[:error] = 'Please login to access this page'
      redirect_to '/users/sign_in'
    else
      redirect_to '/accessdeny'
    end
  end

  def store_current_location
    session[:previous_url] = (%w(/users/sign_in /users/sign_out /sign_in /sign_out).include?(request.path) && !request.xhr?) ? '/dashboard/index' : request.fullpath
  end
end
