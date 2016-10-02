# == Schema Information
#
# Table name: scripts
#
#  id         :integer          not null, primary key
#  script     :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#  slug       :string
#

class Script < ActiveRecord::Base
  extend FriendlyId
  friendly_id :user_username, use: [:slugged, :finders]

  validates :user, presence: true, uniqueness: true
  validates :script, presence: true

  attr_accessor :semester_start, :semester_end

  belongs_to :user

  def user_username
    self.user.username
  end

  ###################################################
  ## Parse the script and return an array of Course objects
  ## Input : Timetable text
  ## Output : Array containing Course objects
  ###################################################
  def parse
    begin
      script = self.script

      result = Array.new
      lines = Array.new

      script.split("\n").each do |line|
        # / is for classes that have two schedules
        # MT90 for example due to the high number of participants have two classes
        # The two classes are separated by a /
        # We only pick the first one
        l = line.split('/').first.nil? ? nil : line.split('/').first.split(' ')
        lines.push(l) unless l.nil? || l.count == 0
      end

      # Get rid of the first line : "---...---" (dashes) if it's present
      if lines[0][0].chars.to_a.uniq.count < 3
        lines.delete_at(0)
      end

      # Get rid of the second line : "login semester numberOfCourses course1 course2 ..." if it's present
      if lines[0][0].length == 8
        lines.delete_at(0)
      end

      # Get rid of the last line : "LE SERVICE des MOYENS d'ENSEIGNEMENT VOUS SOUHAITE BON COURAGE"
      if lines.last.include?("SERVICE") || lines.last.include?("ENSEIGNEMENT") || lines.last.include?("COURAGE")
        lines.delete_at(lines.size - 1)
      end


      # lines[0..-1] should contain courses info
      lines[0..-1].each do |l|
        result.push(Course.new l)
      end

      result
    rescue => e
      raise if Rails.env.development?
      "Can't do it, sorry :(. Please check that you have correctly copied your timetable."
    end
  end

  ###################################################
  ## Interpret the input
  ## Input : Timetable text
  ## Output : Ical file
  ###################################################
  def semester_start
    @semester_start ||= DateTime.new(2015, 9, 1)
  end

  def semester_end
    @semester_end ||= DateTime.new(2016, 1, 8)
  end

  def holiday_all
    Rails.cache.fetch("holiday_all", expires_in: 1.day) do
      Holiday.all
    end
  end

  def invalid_date(date)
    invalid = false

    holiday_all.all.each do |h|
      invalid = invalid || h.get_range.cover?(date)
    end

    invalid
  end

  def to_ical
    parsed_script = self.parse

    cal = Icalendar::Calendar.new

    parsed_class = parsed_script.first
    parsed_script.each do |parsed_class|
      (semester_start..semester_end).step(7) do |d|
        st_date = (d.monday+parsed_class.day).change(hour: parsed_class.st_hour[0..1].to_i, min: parsed_class.st_hour[3..4].to_i)
        end_date = (d.monday+parsed_class.day).change(hour: parsed_class.end_hour[0..1].to_i, min: parsed_class.end_hour[3..4].to_i)
        unless invalid_date(st_date)
          cal.event do |e|
            # st_hour and end_hour format : "HH:mm"
            e.dtstart = st_date
            e.dtend = end_date
            e.summary = parsed_class.course + " - " + parsed_class.type
            e.location = parsed_class.classroom
            e.ip_class = "PRIVATE"
          end
        end
      end
    end
    Holiday.all.each do |h|
      cal.event do |e|
        e.dtstart = h.begin_at
        e.dtstart.ical_params = { "VALUE" => "DATE" }
        e.dtend = h.end_at
        e.dtend.ical_params = { "VALUE" => "DATE" }
        e.summary = h.name
        e.ip_class = "PRIVATE"
      end
    end

    cal
  end

  def write_cal(cal)
    File.open('./test.ics', 'w') { |file| file.write(cal.to_ical) }
  end

end
