class SchedulerController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def index
    @content = Schedule.scheduler_list
  end

  def update_scheduler_status
    sch = Schedule.new
    sch.update_status(params[:id], params[:status])
    sch.run_schedule

    redirect_to action: 'index'
  end

  def update_scheduler_location
    sch = Schedule.new
    sch.update_location(params[:id], params[:location])
    sch.run_schedule

    redirect_to action: 'index'
  end

  def update_scheduler
    date_of_week = params[:dow].nil? ? '' : params[:dow].join(',')
    validate = Schedule.validate_params(params[:start_time], params[:repeat], params[:minute], date_of_week, params[:user_email])

    if validate.blank?
      update_status = Schedule.new.update_schedule(
        id: params[:id],
        note: params[:note],
        start_time: params[:start_time],
        minute: params[:minute],
        weekly: date_of_week,
        email_list: params[:user_email],
        user_email: session[:user_email]
      )

      if update_status.blank?
        flash[:success] = 'Thank you! Your Schedule Test has been updated successful.'
        Thread.new { Schedule.new.run_schedule }
      else
        flash[:error] = update_status.html_safe
      end
    else
      flash[:error] = validate.html_safe
    end

    redirect_to action: 'index'
  end

  def delete_scheduler
    msg = Schedule.delete_scheduler params['id']
    render html: msg.html_safe
  end

  def scheduler_list
    render html: Schedule.scheduler_list.html_safe
  end
end
