class AtgContentPlatformChecker
  class << self
    def validate_content_platform(content_csv_file, language)
      # 1. Get package info from MOAS file
      if language.downcase == 'english'
        moas_titles = AtgMoas.select(:sku, :shortname, :platformcompatibility)
      else
        moas_titles = AtgMoasFr.select(:sku, :shortname, :platformcompatibility)
      end

      return error_message('The MOAS data is empty. Please import MOAS data into Database.') if moas_titles.blank?

      moas_titles_arr = []
      moas_titles.to_a.each do |m|
        platforms = []
        platforms_arr = m[:platformcompatibility].tr(',', ';').split(';')
        platforms_arr.each { |p| platforms.push map_platform(p) }

        moas_titles_arr.push(
          sku: m[:sku],
          title: m[:shortname],
          platforms: platforms
        )
      end

      # 2. Get data from csv file
      spreadsheet = ModelCommon.open_spreadsheet(content_csv_file)
      return error_message('Error while opening the Content Package CSV file.') if spreadsheet.nil?

      headers = ModelCommon.downcase_array_key spreadsheet.row(1)
      return error_message(
        <<-INTERPOLATED_HEREDOC.strip_heredoc
        Make sure that: <br/>
          1. The Content Package data in the first sheet <br/>
          2. The 'Sku', 'Package Id', 'Platforms' headers in the first row. <br/>
          Headers got: #{headers}
      INTERPOLATED_HEREDOC
      ) unless (['sku', 'package id', 'platforms'] - headers).empty?

      csv_packages = []
      (2..spreadsheet.last_row).each do |i|
        row = Hash[[headers, spreadsheet.row(i)].transpose]
        row['platforms'] = 'AND1;' + row['platforms'] if row['package id'].to_s.include? '.apk'

        csv_packages.push(
          sku: row['sku'],
          title: row['display name'],
          platforms: row['platforms']
        ) unless row['sku'].nil? || row['platforms'].nil?
      end

      return error_message 'Content Package CSV file is empty. Please re-check!' if csv_packages.blank?

      csv_titles_arr = combine_csv_platforms csv_packages
      return csv_titles_arr unless csv_titles_arr.is_a?(Array)

      # 3. Compare package platforms between csv and MOAS files
      compare_results = compare_platforms(csv_titles_arr, moas_titles_arr)

      tr_content = ''
      compare_results.each_with_index do |result, index|
        tr_content += <<-INTERPOLATED_HEREDOC.strip_heredoc
        <tr>
          <td>#{index + 1}</td>
          <td>#{result[:sku]}</td>
          <td>#{result[:title]}</td>
          <td>#{result[:moas_platform]}</td>
          <td>#{result[:csv_platform]}</td>
          <td class="#{result[:class_name]}">#{result[:status]}</td>
        </tr>
        INTERPOLATED_HEREDOC
      end

      <<-INTERPOLATED_HEREDOC.strip_heredoc
      <table class="table">
        <tbody>
          <tr>
            <th>#</th>
            <th>SKU</th>
            <th>Title/Display Name</th>
            <th>MOAS Platforms</th>
            <th>CSV Platforms</th>
            <th>Results</th>
          </tr>
          #{tr_content}
        </tbody>
      </table>
      INTERPOLATED_HEREDOC
    end

    def combine_csv_platforms(csv_packages)
      sku_arr = []
      csv_packages.map { |x| sku_arr.push x[:sku] }
      sku_arr.uniq!

      platform_arr = []
      sku_arr.each do |sku|
        platform = ''
        title = ''
        csv_packages.each do |p|
          if p[:sku] == sku
            platform << ';' << p[:platforms]
            title = p[:title]
          end
        end

        platform_arr.push(
          sku: sku,
          title: title,
          platforms: platform.tr(',', ';').split(';').delete_if(&:empty?).uniq
        )
      end

      platform_arr
    rescue => e
      error_message 'Error while getting CSV platforms: ' + e.message
    end

    def map_platform(platform)
      case platform
      when /LeapPad1/
        'LPAD'
      when /LeapPad2/
        'PAD2'
      when /LeapPad3/
        'PAD3'
      when /LeapPad Ultra/
        'PHR1'
      when /LeapPad Platinum/
        'PHR2'
      when /Leapster Explorer/
        'LST3'
      when /LeapsterGS Explorer/
        'GAM2'
      when /LeapReader/
        'LPRD'
      when /LeapTV/
        'THD1'
      when /Epic/
        'AND1'
      else
        platform
      end
    end

    def compare_platforms(csv_titles_arr, moas_titles_arr)
      compare_results = []
      sku_arr = combine_sku(csv_titles_arr, moas_titles_arr)

      sku_arr.each do |sku|
        csv_title = csv_titles_arr.find { |c| c[:sku] == sku }
        moas_title = moas_titles_arr.find { |m| m[:sku] == sku }

        if csv_title && moas_title
          title = moas_title[:title]
          csv_platform = csv_title[:platforms].sort.join(';')
          moas_platform = moas_title[:platforms].sort.join(';')

          if moas_platform == csv_platform
            status = 'Passed'
            class_name = 'pass'
          else
            status = 'Failed'
            class_name = 'failed'
          end
        elsif moas_title
          title = moas_title[:title]
          csv_platform = 'Missing'
          moas_platform = moas_title[:platforms].sort.join(';')
          status = 'N/A'
          class_name = 'text-muted'
        else
          title = csv_title[:title]
          csv_platform = csv_title[:platforms].sort.join(';')
          moas_platform = 'Missing'
          status = 'N/A'
          class_name = 'text-muted'
        end

        compare_results.push(
          sku: sku,
          title: title,
          moas_platform: moas_platform,
          csv_platform: csv_platform,
          status: status,
          class_name: class_name
        )
      end

      compare_results
    end

    def error_message(message)
      <<-INTERPOLATED_HEREDOC.strip_heredoc
      <div class='col-xs-offset-3'>
        <p class = "small-alert alert-error">
          #{message}
        </p>
      </div>
      INTERPOLATED_HEREDOC
    end

    def combine_sku(csv_titles, moas_title)
      temp_sku = []
      csv_titles.each { |c| temp_sku.push c[:sku] }
      moas_title.each { |m| temp_sku.push m[:sku] unless temp_sku.include? m[:sku] }
      temp_sku
    end
  end
end
