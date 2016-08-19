class Activity < ActiveRecord::Base
  def self.to_html(page, user_id)
    condition = user_id.blank? ? '' : " = #{user_id}"
    activities = PublicActivity::Activity.paginate(page: page, per_page: $limit_paging_items).order('created_at desc').where("owner_id#{condition}")

    html = ''
    activities.each do |a|
      case
      when a.key.include?('update')
        action = 'updated'
      when a.key.include?('create')
        action = 'created'
      when a.key.include?('destroy')
        action = 'deleted'
      when a.key.include?('redeem')
        action = 'redeemed'
        redeem_info = a.parameters
      end

      user = User.find_by(id: a.owner_id)

      html += "<tr class='bout'>
      <td>
        #{a.created_at.strftime Rails.application.config.time_format}
      </td>
      <td>
        <a href='/users/logging/u/#{a.owner_id}'>#{user.first_name if user}</a>
      </td>
      <td>"

      if action == 'redeemed'
        html += "#{action} the PIN=#{redeem_info[:pin]}</br>
          Env=#{redeem_info[:env]}, Type=#{redeem_info[:type_pin].gsub('redeem', '')}</br>
          Locale=#{redeem_info[:locale]}, Email=#{redeem_info[:email]}
          </td>
          </tr>"
      else
        html += "#{action} the #{a.trackable_type} ID=#{a.trackable_id}
          </td>
        </tr>"
      end
    end

    { activity_paging: activities, html: html }
  end
end
