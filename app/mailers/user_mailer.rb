class UserMailer < ActionMailer::Base
  include Roadie::Rails::Automatic
  default from: 'sqaautomation@leapfrog.com'
  add_template_helper(EmailHelper)

  def email_test_run(emails, run)
    @run = run
    @root_url = Rails.application.config.root_url
    @server_name = Rails.application.config.server_name
    test_title = "#{run.data['silo']}/#{run.data['suite_name']}"
    start_datetime = run.data['start_datetime'].in_time_zone.strftime Rails.application.config.time_format
    status = Run.status_text(run.data['total_cases'], run.data['total_passed'], run.data['total_failed'], run.data['total_uncertain']).upcase
    env = ", Env = #{run.data['env'].upcase}" unless run.data['env'].blank?
    locale = ", Locale = #{run.data['locale'].upcase}" unless run.data['locale'].blank?
    subject = "[SQAAuto] #{status}#{env}, #{test_title}, #{start_datetime}#{locale}, Server = #{@server_name}"
    attach_type = Rails.application.config.action_mailer.smtp_settings[:attachment_type]

    if attach_type == 'zip'
      attachments['Result.zip'] = File.read(@run.to_attach_file(@root_url, 'zip'), mode: 'rb')
    elsif attach_type == 'html'
      @run.to_attach_file(@root_url, 'html').each do |file|
        attachments[File.basename(file)] = File.read(file).html_safe
      end
    end

    g = Gruff::Pie.new 300
    g.theme = Gruff::Themes::PASTEL
    g.legend_font_size = 35
    g.marker_font_size = 35
    g.data :pass, [run.data['total_passed']], '#5CB85C'
    g.data :fail, [run.data['total_failed']], '#F00000'
    g.data :uncertain, [run.data['total_uncertain']], '#DAA520'
    @pie_chart_data = g.to_blob

    mail(to: emails.tr(';', ','), subject: subject)
  end

  def email_rollup(emails, content, time_amount, title = 'Dashboard')
    @time_stamp = "#{Time.now.in_time_zone.strftime Rails.application.config.time_format}"
    @content = content
    @time_amount = time_amount
    @server_name = Rails.application.config.server_name
    @root_url = Rails.application.config.root_url
    @title = title
    subject = "[SQAAuto] #{title} summary: #{@time_stamp}, Server = #{@server_name}"

    mail(to: emails.tr(';', ','), subject: subject)
  end

  def email_active_request(email)
    @email = email
    subject = "[SQAAuto Admin] TC-QA: Active Request - #{@email}"
    @account_edit_url = "#{Rails.application.config.root_url}/users/create?email=#{@email}"

    # Get admin group emails
    admin_emails = User.find_by_sql('select u.email from users u
                      join user_role_maps ur on u.id = ur.user_id
                      where ur.role_id = 1 and u.is_active = 1').map(&:email).join(',')

    mail(to: admin_emails, subject: subject) unless admin_emails.blank?
  end

  def email_active_response(email, full_name)
    @email = email
    @user_name = full_name
    subject = "[SQAAuto Admin] TC-QA: Account Activated - #{@email}"
    @sign_in_url = "#{Rails.application.config.root_url}/users/sign_in"

    mail(to: @email, subject: subject)
  end
end
