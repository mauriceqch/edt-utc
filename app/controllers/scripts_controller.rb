class ScriptsController < ApplicationController
  before_action :set_script, only: [:show, :edit, :update, :destroy]

  # GET /scripts
  # GET /scripts.json
  def index
    @scripts = Script.all
  end

  # GET /scripts/1
  # GET /scripts/1.json
  def show
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
    #script = parse_script(params['script']['script'])
    #params['script']['script'] = script

    @script = Script.new(script_params)

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

#  private
    # Use callbacks to share common setup or constraints between actions.
    def set_script
      @script = Script.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def script_params
      params.require(:script).permit(:script)
    end

    def parse_script(script)
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
    end

    def split_line(line)
      result = Hash.new
      result['course'] = line[1..4]

      result['type'] = line[12..14]
      result['day'] = line[19..26].gsub('.','')
      result['st_hour'] = line[28..32]
      result['end_hour'] = line[34..38]

      result['frequency'] = line[41]
      result['classroom'] = line[45..49]
      result

    end

end
