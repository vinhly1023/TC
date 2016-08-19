require 'date'

class Version
  def self.tc_git_version
    time = DateTime.parse(`git log -1 --format=%ci`)
    short_hash = `git log -1 --format=%h`
    { version: short_hash, date: "#{time.strftime('%Y/%m/%d')}, #{time.strftime('%I:%M %p')}" }
  rescue => error
    time = Time.now
    { version: "Error: #{error.class.name}", date: "#{time.strftime('%Y/%m/%d')}, #{time.strftime('%I:%M %p')}" }
  end
end
