class Generate
  def self.current_time
    Time.now.strftime('%m%d%Y%H%M%S%3N')
  end

  # Generate email with format "ltrc_[type]_[env]_[locale]_[time]@sharklasers.com"
  def self.email(type = 'atg', env = 'uat', locale = 'us')
    time = current_time
    "ltrc_#{type}_#{env}_#{locale}_#{time}@sharklasers.com".downcase
  end

  def self.state_name(state_code)
    case state_code
    when 'AB'
      return 'Alberta'
    when 'BC'
      return 'British Columbia'
    when 'MB'
      return 'Manitoba'
    when 'NB'
      return 'New Brunswick'
    when 'NL'
      return 'Newfoundland and Labrador'
    when 'NT'
      return 'Northwest Territories'
    when 'NS'
      return 'Nova Scotia'
    when 'NU'
      return 'Nunavut'
    when 'ON'
      return 'Ontario'
    when 'PE'
      return 'Prince Edward Island'
    when 'QC'
      return 'Quebec'
    when 'SK'
      return 'Saskatchewan'
    when 'YT'
      return 'Yukon Territory'
    else
      ''
    end
  end
end
