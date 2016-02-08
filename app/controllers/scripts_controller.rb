# Testing
# rails console
# controller = ScriptsController.new
# parsed_script = controller.parse_script(Script.last.script)
# cal = controller.interpret_parsed_script(parsed_script)

class ScriptsController < ApplicationController
  before_action :set_script, only: [:show, :edit, :update, :destroy, :export, :pdf]
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
    begin
      @parsed_script = @script.parse

      # Sort @parsed_script with day and st_hour
      @parsed_script.sort! do |x, y|
        comparison = x.day <=> y.day
        comparison.zero? ? (x.st_hour <=> y.end_hour) : comparison
      end

      # construct array of courses
      @courses = Array.new(@parsed_script.length)
      @parsed_script.each do |p|
        @courses.push(p.course) unless p.course.in?(@courses)
      end

      # construct courses_events json object for fullcalendar
      @courses_events = Array.new(@parsed_script.length) { Hash.new }
      i = 0
      @parsed_script.each do |p|
        @courses_events[i]["title"] = p.course + " - " + p.type
        tempday = Date.today.monday.to_datetime + p.day
        @courses_events[i]["start"] = tempday.change(hour: p.st_hour[0..1].to_i, min: p.st_hour[3..4].to_i).to_s
        @courses_events[i]["end"] = tempday.change(hour: p.end_hour[0..1].to_i, min: p.end_hour[3..4].to_i).to_s
        i += 1
      end
      @courses_events = @courses_events.to_json.html_safe

    rescue => e
      raise e if Rails.env.development?
      @script.destroy unless @script.nil?
      redirect_to new_script_path, flash: {error: e.message}
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
  def update
    respond_to do |format|
      if @script.update(script_params)
        format.html { redirect_to @script, notice: 'Script was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /scripts/1
  # DELETE /scripts/1.json
  def destroy
    @script.destroy
    respond_to do |format|
      format.html { redirect_to scripts_url, notice: 'Script was successfully destroyed.' }
    end
  end

  def export
    begin
      cal = @script.to_ical
      cal.publish
      render inline: cal.to_ical, content_type: 'text/calendar'
    rescue => e
      raise e if Rails.env.development?
      render inline: "Woops, that didn't quite work !"
    end
  end

  def pdf
   @parsed_script = @script.parse

      # construct array of courses
      @courses = Array.new(@parsed_script.length)
      @parsed_script.each do |p|
        @courses.push(p.course) unless p.course.in?(@courses)
      end

    @parsed_script.each do |p|
      p.day = p.day == 3 ? 'Th' : Date::DAYNAMES[(p.day+1)%7][0]
    end

    render 'scripts/pdf.pdf.rtex' 
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

end
