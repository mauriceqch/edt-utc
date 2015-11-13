# Testing
# rails console
# controller = ScriptsController.new
# parsed_script = controller.parse_script(Script.last.script)
# cal = controller.interpret_parsed_script(parsed_script)

class ScriptsController < ApplicationController
  before_action :set_script, only: [:show, :edit, :update, :destroy, :export]
  require 'icalendar'

  def index
    @script = current_user.script
    if @script
      redirect_to script_url(@script)
    else
      redirect_to new_script_url
    end
  end

  # GET /scripts/1
  # GET /scripts/1.json
  def show
    @parsed_script = parse_script(@script.script)

    if @parsed_script.is_a?(Hash)
      @parsed_script.sort! do |x, y|
        comparison = x["day"] <=> y["day"]
        comparison.zero? ? (x["st_hour"] <=> y["end_hour"]) : comparison
      end
    end

    @courses = Array.new
    @parsed_script.each do |p|
      @courses.push(p["course"]) unless p["course"].in?(@courses)
    end

  end

  # GET /scripts/new
  def new
    @script = Script.new
  end

  # GET /scripts/1/edit
  def edit
  end

  # POST /scripts
  # POST /scripts.json
  def create
    old_script = current_user.script
    if old_script
      old_script.destroy
    end

    @script = Script.new(script_params)
    @script.user = current_user

    respond_to do |format|
      if @script.save
        format.html { redirect_to @script, notice: 'Script was successfully created.' }
        format.json { render :show, status: :created, location: @script }
      else
        format.html { render :new }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scripts/1
  # PATCH/PUT /scripts/1.json
  def update
    respond_to do |format|
      if @script.update(script_params)
        format.html { redirect_to @script, notice: 'Script was successfully updated.' }
        format.json { render :show, status: :ok, location: @script }
      else
        format.html { render :edit }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scripts/1
  # DELETE /scripts/1.json
  def destroy
    @script.destroy
    respond_to do |format|
      format.html { redirect_to scripts_url, notice: 'Script was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def export
    begin
      parsed_script = parse_script(@script.script)
      cal = interpret_parsed_script(parsed_script)
      cal.publish
      render inline: cal.to_ical, content_type: 'text/calendar'
    rescue
      render inline: "Woops, that didn't quite work !"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_script
    @script = current_user.script
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def script_params
    params.require(:script).permit(:script)
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
  def parse_script(script)
    begin
      result = Array.new
      lines = Array.new

      script.split("\n").each do |line|
        # / is for classes that have two schedules
        # MT90 for example due to the high number of participants have two classes
        # The two classes are separated by a /
        # We only pick the first one
        l = line.split('/').first.split(' ')
        lines.push(l) unless l.count == 0
      end

      lines[2..-1].each do |l|
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

    result['type'] = type_translation[line[i]] unless type_translation[line[i]].nil?

    # If it's not 'C' then there is another field in the line
    # Type additional info : group
    if line[i] != 'C'
      i += 1
      result['type'] += line[i]
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
  ## Input : Hash containing information about each class (line: class, columns: information about the class)
  ## Output : Ical file
  ###################################################
  def semester_start
    DateTime.new(2015,9,1)
  end

  def semester_end
    DateTime.new(2016,1,8)
  end

  def invalid_date(date)
    vacances_toussaint = DateTime.new(2015,10,26)..(DateTime.new(2015,10,31)+1)
    medians = DateTime.new(2015,11,3)..(DateTime.new(2015,11,9)+1)
    vacances_noel = DateTime.new(2015,12,24)..(DateTime.new(2016,1,2)+1)

    fetetravail = DateTime.new(2015,5,1)..DateTime.new(2015,5,2)
    fetevictoire = DateTime.new(2015,5,8)..DateTime.new(2015,5,9)
    fetearmistice = DateTime.new(2015,11,10)..DateTime.new(2015,11,11)

    vacances_toussaint.cover?(date) || medians.cover?(date) || vacances_noel.cover?(date) || fetetravail.cover?(date) || fetevictoire.cover?(date) || fetearmistice.cover?(date)
  end

  def interpret_parsed_script(parsed_script)
    cal = Icalendar::Calendar.new

    parsed_class = parsed_script.first
    parsed_script.each do |parsed_class|
      (semester_start..semester_end).step(7) do |d|
          st_date = (d.monday+parsed_class["day"]).change(hour: parsed_class["st_hour"][0..1].to_i, min: parsed_class["st_hour"][3..4].to_i)
          end_date = (d.monday+parsed_class["day"]).change(hour: parsed_class["end_hour"][0..1].to_i, min: parsed_class["end_hour"][3..4].to_i)
          unless invalid_date(st_date)
            cal.event do |e|
              # st_hour and end_hour format : "HH:mm"
              e.dtstart     = st_date
              e.dtend       = end_date
              e.summary     = parsed_class["course"] + " - " + parsed_class["type"]
              e.ip_class    = "PRIVATE"
            end
          end
      end
    end

    cal
  end

  def write_cal(cal)
    File.open('./test.ics','w') { |file| file.write(cal.to_ical) }
  end
end
