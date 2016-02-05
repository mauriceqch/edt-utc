class Course
  # Non persisted model (not saved into database)
  include ActiveModel::Model

  attr_accessor :course, :type, :day, :st_hour, :end_hour, :frequency, :classroom

  # Analyze the line and create a Course object containing the information
  def initialize(line)
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
    @course = line[i]

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
      @type = type_translation[line[i][0]] unless type_translation[line[i][0]].nil?

      # If it's not 'C' then there is another field in the line
      # Type additional info : group
      if line[i] != 'C'
        @type += line[i][1..2]
      end
    else
      # Case : length : 1
      # "D" for example
      @type = type_translation[line[i]] unless type_translation[line[i]].nil?

      # If it's not 'C' then there is another field in the line
      # Type additional info : number of group
      # Example : for "D 1" the number of the group is "1"
      if line[i] != 'C'
        i += 1
        @type += line[i]
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
    @day = day_translation[line[i].gsub('.', '')]

    # Field 3 or 4 depending on type value
    # Contains start hour, frequency, and classroom
    # Sample : "8:15-12:15,F1,S=RN104"
    last_field = line.last.split(',')
    last_field_schedule = last_field.first.split('-')

    @st_hour = last_field_schedule.first
    @end_hour = last_field_schedule.last

    @frequency = last_field.second.last
    @classroom = last_field.last.split('=').last
  end

end