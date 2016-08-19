class AtgContentPlatformCheckerController < ApplicationController
  def index
  end

  def validate_content_platform
    language = params[:language]
    content_platform_csv_file = params[:content_platform_csv_file]

    # temporary path of uploaded files
    path = File.join(Dir.tmpdir, "#{File.basename(Rails.root.to_s)}_#{Time.now.to_i}_#{rand(100)}")
    Dir.mkdir(path)

    # Upload file to server
    csv_file_name = content_platform_csv_file.blank? ? false : ModelCommon.upload_file(path, content_platform_csv_file)
    if csv_file_name
      @message = AtgContentPlatformChecker.validate_content_platform(File.join(path, csv_file_name), language)
    else
      @message = AtgContentPlatformChecker.error_message 'Please select correct Excel/CSV file format'
    end
  rescue => e
    @message = AtgContentPlatformChecker.error_message e.message
  ensure
    FileUtils.rm_rf path
    render 'index'
  end
end
