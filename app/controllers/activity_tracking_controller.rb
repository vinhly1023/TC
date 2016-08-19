class ActivityTrackingController < ApplicationController
  def logging
    act = Activity.to_html params[:page], params[:user_id]
    @activities = act[:activity_paging]
    @html = act[:html]

    render 'logging'
  end

  def update_limit
    config = RailsAppConfig.new
    limit_number = params[:limit_log_paging]

    begin
      re = config.update_paging_number limit_number
      flash[:error] = 'Please enter a number' if re == RailsAppConfig::NOT_A_NUMBER_CONST
    rescue => e
      flash[:error] = 'An error occurred while updating - please try again!'
      Rails.logger.error "Error while updating limit activity number per page #{ModelCommon.full_exception_error(e)}"
    end

    redirect_to '/users/logging'
  end
end
