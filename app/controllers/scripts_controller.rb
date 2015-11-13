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
    parsed_script = parse_script(@script.script)
    cal = interpret_parsed_script(parsed_script)
    cal.publish
    render inline: cal.to_ical, content_type: 'text/calendar'
  end

  #  private
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
  def parse_script(script)
    begin
      # Split lines into array
      s = script.split("\n")
      s2 = Array.new

      # Delete empty lines
      s.each do |spart|
        s2.push(spart) unless spart.length < 10
      end

      s3 = Array.new

      s2[2..-1].each do |spart| s3.push(split_line(spart)) end
      #s3 (array) elements sample :
      #{"course"=>"EI03", "type"=>"C  ", "day"=>"LUNDI", "st_hour"=>"18:45", "end_hour"=>"19:45", "frequency"=>"1", "classroom"=>"RN104"}
      #{"course"=>"EI03", "type"=>"D 1", "day"=>"SAMEDI", "st_hour"=>" 8:15", "end_hour"=>"12:15", "frequency"=>"1", "classroom"=>"RN104"}
      #{"course"=>"LG30", "type"=>"D 2", "day"=>"MERCREDI", "st_hour"=>"10:15", "end_hour"=>"12:15", "frequency"=>"1", "classroom"=>"FA413"}
      #{"course"=>"LG30", "type"=>"T 3", "day"=>"LUNDI", "st_hour"=>"13:00", "end_hour"=>"14:00", "frequency"=>"1", "classroom"=>"FA410"}
      #{"course"=>"SR01", "type"=>"C  ", "day"=>"LUNDI", "st_hour"=>"14:15", "end_hour"=>"16:15", "frequency"=>"1", "classroom"=>"FA104"}
      #{"course"=>"SR01", "type"=>"D 1", "day"=>"LUNDI", "st_hour"=>"16:30", "end_hour"=>"18:30", "frequency"=>"1", "classroom"=>"FA506"}
      #{"course"=>"NF16", "type"=>"C  ", "day"=>"MERCREDI", "st_hour"=>"14:15", "end_hour"=>"16:15", "frequency"=>"1", "classroom"=>"FA100"}
      #{"course"=>"NF16", "type"=>"D 6", "day"=>"JEUDI", "st_hour"=>"10:15", "end_hour"=>"12:15", "frequency"=>"1", "classroom"=>"FA418"}
      #{"course"=>"NF16", "type"=>"T 7", "day"=>"VENDREDI", "st_hour"=>"16:30", "end_hour"=>"18:30", "frequency"=>"2", "classroom"=>"FB115"}
      #{"course"=>"IA01", "type"=>"C  ", "day"=>"LUNDI", "st_hour"=>"10:15", "end_hour"=>"12:15", "frequency"=>"1", "classroom"=>"FA201"}
      #{"course"=>"IA01", "type"=>"D 4", "day"=>"JEUDI", "st_hour"=>"14:15", "end_hour"=>"16:15", "frequency"=>"1", "classroom"=>"FA405"}
      #{"course"=>"IA01", "type"=>"T 2", "day"=>"JEUDI", "st_hour"=>" 8:00", "end_hour"=>"10:00", "frequency"=>"2", "classroom"=>"FB115"}
      #{"course"=>"GE37", "type"=>"C  ", "day"=>"VENDREDI", "st_hour"=>"10:15", "end_hour"=>"12:15", "frequency"=>"1", "classroom"=>"RB110"}
      #{"course"=>"GE37", "type"=>"D 1", "day"=>"MARDI", "st_hour"=>" 9:00", "end_hour"=>"12:00", "frequency"=>"1", "classroom"=>"RO128"}
      #{"course"=>"MT12", "type"=>"C  ", "day"=>"LUNDI", "st_hour"=>" 8:00", "end_hour"=>"10:00", "frequency"=>"1", "classroom"=>"FA202"}
      #{"course"=>"MT12", "type"=>"D 1", "day"=>"MARDI", "st_hour"=>"16:30", "end_hour"=>"18:30", "frequency"=>"1", "classroom"=>"FA518"}

      s3
    rescue => e
      "Entrée incorrecte"
    end

  end

  # Analyze the line and create a hash containing the information
  def split_line(line)
    result = Hash.new
    result['course'] = line[1..4]

    result['type'] = line[12..14]

    day_translation = Hash.new
    day_translation['LUNDI'] = 0
    day_translation['MARDI'] = 1
    day_translation['MERCREDI'] = 2
    day_translation['JEUDI'] = 3
    day_translation['VENDREDI'] = 4
    day_translation['SAMEDI'] = 5
    day_translation['DIMANCHE'] = 6

    result['day'] = day_translation[line[19..26].gsub('.','')]


    result['st_hour'] = line[28..32]
    result['end_hour'] = line[34..38]

    result['frequency'] = line[41]
    result['classroom'] = line[45..49]
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
