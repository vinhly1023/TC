require 'github/markup'

class UsersController < ApplicationController
  def sign_in
    flash.clear
    @user = User.new
    @user_sgi = User.new
    return unless request.post?

    @user_sgi[:email] = params[:user_email]
    error = @user_sgi.sign_in params[:user_email], params[:user_password]
    return flash.now[:error] = error.html_safe unless error.blank?

    session[:user_email] = params[:user_email]
    user_info = User.user_info_by_email(params[:user_email])
    session[:user_role] = user_info[:role_id]
    session[:first_name] = user_info[:first_name]

    redirect_to session[:previous_url].nil? ? '/dashboard/index' : session[:previous_url]
  end

  def sign_out
    session[:user_email] = nil
    session[:user_role] = nil
    session[:first_name] = nil
    session[:previous_url] = nil

    redirect_to users_sign_in_path
  end

  def create
    flash.clear
    @user = User.new

    # active user
    if request.get? && params[:email]
      search_user params[:email]
      return
    end

    case params[:commit]
    when 'Create'
      @user.assign_attributes user_params
      error = @user.create_user params[:role_id]
      if error.blank?
        flash.now[:success] = 'Your account is created successfully.'
      else
        flash.now[:error] = error.html_safe
      end
    when 'Search'
      search_user params[:email]
    end
  end

  def search_user(email)
    @user = User.user_info_by_email(email)
    if @user.empty?
      flash.now[:error] = 'Could not find the email - please try again!'
      render 'create'
    else
      render 'edit'
    end
  end

  def sign_up
    flash.clear
    @user_sgi = User.new
    @user = User.new
    return unless request.post?

    @user.assign_attributes user_params
    error = @user.create_user
    if error.blank?
      Thread.new { UserMailer.email_active_request(params[:email]).deliver }
      flash.now[:success] = 'Your account is created successfully. Please contact Test Central Administrator to activate your account!'
      @user = User.new
    else
      flash.now[:error] = error.html_safe
    end

    render 'sign_in'
  end

  def edit
    flash.clear

    @user = User.find_by(id: params[:id])
    return flash.now[:error] = "Could not find user by id #{params[:id]}" unless @user

    is_active = @user[:is_active]
    error = @user.update_user(user_params, params[:role_id])
    return flash.now[:error] = error.html_safe unless error.blank?

    Thread.new do
      Rails.logger.info "Send active email to #{params[:email]}"
      UserMailer.email_active_response(params[:email], "#{params[:first_name]} #{params[:last_name]}").deliver
    end if is_active == false && params[:is_active].to_i == 1

    flash.now[:success] = 'Your account is updated successfully'
    @user = User.user_info_by_email(params[:email])
  end

  def help
    @link_list = FileUtilsC.get_filesname_recursively 'guides'
    @faqs = JSON.parse(File.read('config/faqs.json'), symbolize_names: true)
  end

  def download
    send_file params[:file]
  end

  def view_markdown
    @content = GitHub::Markup.render params[:file]
  end

  private

  def user_params
    params.permit(:first_name, :last_name, :email, :password, :is_active)
  end
end
