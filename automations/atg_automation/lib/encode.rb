class RspecEncode
  def self.encode_title(text)
    return text.to_s unless text

    str = text.to_s.dup
    str.gsub!("\u0099", '™')
    str.gsub!("\u2122", '™')
    str.gsub!('&trade;', '™')
    str.gsub!("\u0092", "'")
    str.gsub!("\u2019", "'")
    str.gsub!("\u2026", '...')
    str.gsub!("\u0096", '–')
    str.gsub!("\u00A0", '')
    str.gsub!("\u00C0", 'Ã€')
    str.gsub!("\u00E9", 'Ã©')
    str.gsub!("\u2044", '/')
    str.gsub!("\u00C9", 'Ã‰')
    str.gsub!("\u0095", '·')
    str.gsub!("\u009C", 'œ')
    str.gsub!('&middot;', "\u00B7")
    str.gsub!("\u2022", "\u00B7")
    str.gsub!("\u2219", "\u00B7")
    str.delete!("\n")
    str.strip!

    str
  end

  def self.encode_description(text)
    return text.to_s unless text

    str = text.to_s.dup
    str.gsub!(/\r+/, '')
    str.gsub!(/\n+/, ' ')
    str.gsub!('<br>', ' ')

    doc = Nokogiri::HTML(str)
    str = doc.text
    str.gsub!("\u00A0", ' ')
    str.gsub!(/['\u2019''\u2018']/, "'")
    str.gsub!("\u2013", '-')
    str.gsub!("\u2014", '-')
    str.gsub!("\u0097", '-')
    str.gsub!("\u0099", '™')
    str.gsub!("\u2122", '™')
    str.gsub!('â„¢', '™')
    str.gsub!("\u0092", "'")
    str.gsub!("\u2026", '...')
    str.gsub!("\u0096", '-')
    str.gsub!("\u0093", "\"")
    str.gsub!("\u0094", "\"")
    str.gsub!("\u0095", '·')
    str.gsub!("\u009C", 'œ')
    str.gsub!('', '...')
    str.gsub!("\u00C0", 'Ã€')
    str.gsub!("\u00E9", 'Ã©')
    str.gsub!("\u2044", '/')
    str.gsub!("\u00C9", 'Ã‰')
    str.gsub!("N\u01D0 h\u01CEo", 'NÇ� hÇŽo')
    str.gsub!("N\u030Ci h\u030Cao", 'NÇ� hÇŽo')
    str.gsub!(/['\u201C''\u201D']/, '"')
    str.gsub!(/[ ]+/, ' ')
    str.gsub!('.?', '. ')
    str.tr!('’', '\'') # SQAAUTO-1608
    str.strip!

    remove_nbsp(str)
  end

  def self.normalizes_unexpected_characters(text)
    return text.to_s unless text

    str = text.to_s.dup
    str.gsub!(/\r+/, '')
    str.gsub!(/\n+/, ' ')
    str.gsub!(/[ ]+/, ' ')
    str.strip!

    str
  end

  def self.remove_nbsp(text)
    nbsp = Nokogiri::HTML('&nbsp;').text
    text.gsub(nbsp, ' ').delete("\n").strip
  end
end
