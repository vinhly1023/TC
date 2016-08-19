class AtgPromotion < ActiveRecord::Base
  def self.atg_promotion_data
    AtgPromotion.order(:env).pluck(:env, :promo_name, :num_prods, :prod_ids)
  end

  def self.atg_upload_promotion_code(env, promotion_file)
    return ModelCommon.error_message('Please select Excel/CSV Hostname file to upload.') unless promotion_file

    promo_content = ModelCommon.open_spreadsheet promotion_file
    return ModelCommon.error_message('Please make sure promotion code file format is Excel/CSV.') unless promo_content

    promo_headers = ModelCommon.downcase_array_key promo_content.row(1)
    pre_headers = ['promoname', 'numprods', 'prod1', 'prod2', 'prod3', 'prod4']
    return ModelCommon.error_message("Please make sure promotion code file header includes: #{pre_headers.join(', ')}") unless (pre_headers - promo_headers).empty?

    message = ''
    AtgPromotion.new.transaction do
      begin
        # Delete all data
        AtgPromotion.delete_all("env = '#{env}'")

        # Import data row by row
        (2..promo_content.last_row).each do |i|
          temp_row = promo_content.row(i)
          prod_ids = temp_row.drop(2).reject { |e| e.to_s.empty? }.join(',')

          AtgPromotion.create(
            env: env,
            promo_name: temp_row[0],
            num_prods: temp_row[1],
            prod_ids: prod_ids
          )
        end

        message = ModelCommon.success_message 'Promotion Code is uploaded successfully.'
      rescue => e
        message = ModelCommon.error_message("Error while uploading data: <br>#{e.message}")
        raise ActiveRecord::Rollback
      end
    end

    message
  end
end
