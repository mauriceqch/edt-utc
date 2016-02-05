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

  belongs_to :user

  def user_username
    self.user.username
  end

  ###################################################
  ## Analyze the input
  ## Input : Timetable text
  ## Output : Hash containing information about each class (line: class, columns: information about the class)
  ###################################################
  # Parse the script and return a hash of hashes containing information about each class
  # output (array) elements sample :
  #{"course"=>"EI03", "type"=>"C  ", "day"=>"LUNDI", "st_hour"=>"18:45", "end_hour"=>"19:45", "frequency"=>"1", "classroom"=>"RN104"}
  #{"course"=>"EI03", "type"=>"D 1", "day"=>"SAMEDI", "st_hour"=>" 8:15", "end_hour"=>"12:15", "frequency"=>"1", "classroom"=>"RN104"}
  # ...
  #{"course"=>"MT12", "type"=>"D 1", "day"=>"MARDI", "st_hour"=>"16:30", "end_hour"=>"18:30", "frequency"=>"1", "classroom"=>"FA518"}
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
        result.push(split_line(l))
      end

      result
    rescue
      "Can't do it, sorry :(. Please check that you have correctly copied your timetable."
    end
  end

  # Analyze the line and create a hash containing the information
  def split_line(line)
    result = Hash.new

    # Treat this case
    #  "SPJE       D 1    JEUDI... 14:15-18:15,F1,S=     *"
    if line.last == '*'
      line.pop
      # Add a space for classroom parsing
      # Hacks, hacks everywhere ...
      line[-1] += ' '
    end

    # Field 0
    # Course
    i = 0
    result['course'] = line[i]

    # Field 1
    # Type
    i += 1
    type_translation = Hash.new
    type_translation['C'] = 'C'
    type_translation['T'] = 'TP'
    type_translation['D'] = 'TD'

    if line[i].length > 1
      # Case : length : 3
      #  "SPJE       D10    JEUDI... 14:15-18:15,F1,S=     *"
      # Cause : the type and number of groups take up to three characters
      # When the number of groups is >= 10 there is no space between
      # type and number
      # "D10" : not separated by a space
      # Consequence : the number of elements is diminished by one
      # We have to do some parsing on that element
      result['type'] = type_translation[line[i][0]] unless type_translation[line[i][0]].nil?

      # If it's not 'C' then there is another field in the line
      # Type additional info : group
      if line[i] != 'C'
        result['type'] += line[i][1..2]
      end
    else
      # Case : length : 1
      # "D" for example
      result['type'] = type_translation[line[i]] unless type_translation[line[i]].nil?

      # If it's not 'C' then there is another field in the line
      # Type additional info : number of group
      # Example : for "D 1" the number of the group is "1"
      if line[i] != 'C'
        i += 1
        result['type'] += line[i]
      end
    end


    day_translation = Hash.new
    day_translation['LUNDI'] = 0
    day_translation['MARDI'] = 1
    day_translation['MERCREDI'] = 2
    day_translation['JEUDI'] = 3
    day_translation['VENDREDI'] = 4
    day_translation['SAMEDI'] = 5
    day_translation['DIMANCHE'] = 6

    # Field 2 or 3 depending on type value
    # Day
    i += 1
    result['day'] = day_translation[line[i].gsub('.', '')]

    # Field 3 or 4 depending on type value
    # Contains start hour, frequency, and classroom
    # Sample : "8:15-12:15,F1,S=RN104"
    last_field = line.last.split(',')
    last_field_schedule = last_field.first.split('-')

    result['st_hour'] = last_field_schedule.first
    result['end_hour'] = last_field_schedule.last

    result['frequency'] = last_field.second.last
    result['classroom'] = last_field.last.split('=').last
    result
  end

  ###################################################
  ## Interpret the input
  ## Input : Timetable text
  ## Output : Ical file
  ###################################################
  def semester_start
    DateTime.new(2015, 9, 1)
  end

  def semester_end
    DateTime.new(2016, 1, 8)
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
        st_date = (d.monday+parsed_class["day"]).change(hour: parsed_class["st_hour"][0..1].to_i, min: parsed_class["st_hour"][3..4].to_i)
        end_date = (d.monday+parsed_class["day"]).change(hour: parsed_class["end_hour"][0..1].to_i, min: parsed_class["end_hour"][3..4].to_i)
        unless invalid_date(st_date)
          cal.event do |e|
            # st_hour and end_hour format : "HH:mm"
            e.dtstart = st_date
            e.dtend = end_date
            e.summary = parsed_class["course"] + " - " + parsed_class["type"]
            e.location = parsed_class["classroom"]
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
