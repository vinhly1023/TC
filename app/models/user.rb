require 'digest'

class User < ActiveRecord::Base
  include PublicActivity::Common
  cattr_accessor :current_user
  has_one :user_role_map
  validates :email, presence: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true
  validates :email, uniqueness: true
  validates :password, presence: true
  validates :password, length: { minimum: 6 }, allow_blank: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  def sign_in(username, password)
    user = User.where(email: username, password: Digest::MD5.hexdigest(password)).first

    return 'Sorry, your username and password are incorrect - Please try again!' unless user
    'Sorry, your account is not activated - Please contact administrator to active your account!' unless user[:is_active]
  end

  def create_user(role = 3)
    self[:is_active] = 0 unless self[:is_active]

    if self.valid?
      self[:password] = Digest::MD5.hexdigest(self[:password])
      save(validate: false)

      role_map = UserRoleMap.new(
        role_id: role,
        user_id: self[:id]
      )

      if role_map.save
        create_activity key: 'user.create', owner: User.current_user
      else
        error = 'Error while adding user\'s role. Please try again!'
        destroy
      end
    else
      error = errors.full_messages.join('<br>')
    end

    error
  end

  def update_user(user_data, role)
    user_params = user_data.dup
    user_params.delete(:email) # do not update email address

    if user_params[:password].blank?
      user_params.delete(:password)
      update(user_params)
    else
      update(user_params)
      update_attribute(:password, Digest::MD5.hexdigest(user_params[:password]))
    end

    return errors.full_messages.join('<br>') if errors.any?

    create_activity key: 'user.update', owner: User.current_user
    'Error while updating user\'s role. Please try again!' unless UserRoleMap.where(user_id: self[:id]).first.update(role_id: role)
  end

  def self.user_info_by_email(email)
    user_info = User.joins(:user_role_map).where(email: email).select(:id, :first_name, :last_name, :email, :password, :is_active, :role_id).first
    return {} unless user_info

    {
      id: user_info[:id],
      first_name: user_info[:first_name],
      last_name: user_info[:last_name],
      email: user_info[:email],
      password: user_info[:password],
      is_active: user_info[:is_active],
      role_id: user_info[:role_id]
    }
  end

  def self.user_info_by_id(id)
    user_info = User.select(:id, :first_name, :last_name, :email, :is_active).find_by(id: id)
    return {} unless user_info

    {
      id: user_info[:id],
      first_name: user_info[:first_name],
      last_name: user_info[:last_name],
      email: user_info[:email],
      is_active: user_info[:is_active],
      full_name: "#{user_info[:first_name]} #{user_info[:last_name]}"
    }
  end
end
