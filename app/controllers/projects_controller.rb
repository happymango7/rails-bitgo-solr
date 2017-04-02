class ProjectsController < ApplicationController
  load_and_authorize_resource  :except => [:get_activities, :project_admin,:send_project_email, :show_task,:send_project_invite_email,:contacts_callback ,:read_from_mediawiki, :write_to_mediawiki]
  autocomplete :projects, :title, :full => true
  autocomplete :users, :name, :full => true
  autocomplete :tasks, :title, :full => true
  before_action :set_project, only: [:show, :taskstab, :show_project_team, :edit, :update, :destroy, :saveEdit, :updateEdit, :follow, :rate, :discussions, :read_from_mediawiki, :write_to_mediawiki]
  before_action :get_project_user, only: [:show, :taskstab, :show_project_team]
  skip_before_action :verify_authenticity_token, only: [:rate]
  # skip_authorization_check []

  def index
    if user_signed_in?
      if current_user.user_wallet_address.blank?
        current_user.assign_address
        unless current_user.user_wallet_address.user_keys.blank?
          @download_keys = true
        end
      end
    end
    @projects = Project.all
    #Every Time someone visits home page it ittrate N times Thats not a good approch .
    # Project.all.each { |project| project.create_team(name: "Team #{project.id}") unless !project.team.nil? }
    @featured_projects = Project.page params[:page]
  end

  def original_url
    request.base_url + request.original_fullpath
  end

  def send_project_invite_email
    session[:success_contacts] = nil
    @array = params[:emails].split(',')
    @array.each do |key|
      InvitationMailer.invite_user_for_project(key, current_user.name, Project.find(session[:idd]).title, session[:idd]).deliver_now
    end
    session[:success_contacts] = "Project link has been shared  successfully with your friends!"
    session[:project_id] = session[:idd]
    redirect_to controller: 'projects', action: 'taskstab', id: session[:idd]
  end

  def send_project_email
    respond_to do |format|
      unless params['email'].blank?
        if current_user.blank?
          @notice = "ERROR: Please sign in to continue."
          format.js {}
        else
        begin
          InvitationMailer.invite_user_for_project( params['email'],current_user.name,
          Project.find(params['project_id']).title , params['project_id']).deliver_later
          format.html { redirect_to controller: 'projects', action: 'taskstab', id: params['project_id'], notice: "Project link has been sent to #{params[:email]}" }
          @notice = "Project link has been sent to #{params[:email]}"
          format.js {}
        rescue => e
          @notice = "Error ".concat e.inspect
          format.js {}
        end

        end
      else
        session[:project_id] =  session[:idd]
        format.html { redirect_to controller: 'projects', action: 'taskstab', id: params['project_id'], notice: "Please provide receiver email." }
        @notice = 'Please provide receiver email.'
        format.js {}
      end
    end
  end

  def contacts_callback
    @contacts = request.env['omnicontacts.contacts']
    respond_to do |format|
      format.html
    end
  end

  def failure
    session[:failure_contacts] = nil
    session[:project_id] =  session[:idd]
    redirect_to controller: 'projects', action: 'taskstab', id: session[:idd]
    session[:failure_contacts] = "No, Project invitation Email was sent to your Friends!"
  end

  def show_task
    @task = Task.find(params[:id])
    @task_comments = @task.task_comments
    @task_attachment = TaskAttachment.new
    @task_attachments = @task.task_attachments
    @task_team = TeamMembership.where(task_id: @task.id)
    task_comment_ids = @task.task_comments.collect(&:id)
    @activities = Activity.where("(targetable_type= ? AND targetable_id=?) OR (targetable_type= ? AND targetable_id IN (?))", "Task",@task.id,"TaskComment",task_comment_ids  ).order('created_at DESC')
    project_admin
    respond_to :js
  end

  def autocomplete_user_search
    term = params[:term]
    @projects = Project.order(:title).where(
      "LOWER(title) LIKE ? or LOWER(description) LIKE ? or LOWER(short_description) LIKE ? or LOWER(request_description) LIKE ?",
      "%#{params[:term]}%", "%#{params[:term]}%", "%#{params[:term]}%", "%#{params[:term]}%").map{|p|"#{p.title}"}
    @result = @projects + Task.order(:title).where(
      "LOWER(title) LIKE ? or LOWER(description) LIKE ? or LOWER(short_description) LIKE ? or LOWER(condition_of_execution) LIKE ?", 
      "%#{params[:term]}%","%#{params[:term]}%", "%#{params[:term]}%", "%#{params[:term]}%").map{|t|"#{t.title}"}
    respond_to do |format|
      format.html {render text: @result}
      format.json { render json: @result.to_json,status: :ok}
     end
  end

  def user_search
    #User search has been disabled because we don't have user's public profile or show page yet available in application we will just add Sunspot.search(Project,Task,User) later
    @search = Sunspot.search(Task,Project) do
      # keywords params[:title]
      fulltext params[:title] do
        query_phrase_slop 1
      end
    end
    @results = @search.results
    unless @results.blank?
      respond_to do |format|
      # format.html {render  :search_results}
        format.js
      end
    else
      respond_to do |format|
        format.js
       # format.html {render  :search_results ,alert: 'Sorry no results match with your search'}
      end
    end
  end

  def search_results
    #display solar search results
  end

  def project_admin
    @project_admin =  TeamMembership.where( "team_id = ? AND state = ?", @task.project.team.id, 'admin').collect(&:team_member_id) rescue nil
  end

  def show
    # @comments = @project.project_comments.all
    # @proj_admins_ids = @project.proj_admins.ids
    # @followed = false
    # @current_user_id = 0
    # @rate = @project.rate_avg
    # if user_signed_in?
    #   @followed = @project.followers.pluck(:id).include? current_user.id
    #   @current_user_id = current_user.id
    #   @change_leader_invitation = @project.change_leader_invitations.pending.where(new_leader: current_user.email).first
    # end
    # respond_to do |format|
    #   format.html
    #   format.js {render(layout: false)}
    # end

    redirect_to taskstab_project_path(@project.id)
  end

  def follow
    redirect_to @project and return if current_user.id == @project.user_id
    if params[:follow] == 'true'
      flash[:alert] = follow_project.errors.full_messages.to_sentence unless @project.follow!(current_user)
    else
      current_user.followed_projects.delete @project
    end
    redirect_to @project
  end

  def unfollow
    project = Project.find params[:id]
    project.unfollow!(current_user)
    flash[:notice] = "You stopped following project " + project.title
    redirect_to :my_projects
  end

  def rate
    @rate = @project.project_rates.find_or_create_by(user_id: current_user.id)
    @rate.rate = params[:rate]
    @rate.save
    render json: {
      rate: @rate,
      average: @project.rate_avg
    }
  end

 def get_activities
   @task=Task.find(params[:id])
   task_comment_ids = @task.task_comments.collect(&:id)
   @activities = Activity.where("(targetable_type= ? AND targetable_id=?) OR (targetable_type= ? AND targetable_id IN (?))", "Task",@task.id,"TaskComment",task_comment_ids  ).order('created_at DESC').limit(30)
   respond_to :js
 end

  # GET /projects/1/taskstab
  def taskstab
    @comments = @project.project_comments.all
    @proj_admins_ids = @project.proj_admins.ids
    @current_user_id = 0
    if user_signed_in?
      @current_user_id = current_user.id
    end

    @followed = false
    @rate = 0
    if user_signed_in?
      @followed = @project.project_users.pluck(:user_id).include? current_user.id
      @current_user_id = current_user.id
      @rate = @project.project_rates.find_by(user_id: @current_user_id).try(:rate).to_i
    end
    tasks = @project.tasks.all
    @tasks_count =tasks.count
    @sourcing_tasks = tasks.where(state: ["pending", "accepted"]).all
    @doing_tasks = tasks.where(state: "doing").all
    @suggested_tasks = tasks.where(state: "suggested_task").all
    @reviewing_tasks = tasks.where(state: "reviewing").all
    @done_tasks = tasks.where(state: "completed").all
    @contents = ''
    result = current_user.page_read @project.title
    if result
      if result["status"] == 'success'
        @contents = result["html"]
      else
        # Create new page
        current_user.page_write @project.title, ''
        result = current_user.page_read @project.title
        @contents = ''
      end
    end
  end

  def show_project_team
    respond_to do |format|
      format.js
    end
  end

  def new
    @project = Project.new
  end

  def edit

  end

  def create
    @project = current_user.projects.build(project_params)
    @project.user_id = current_user.id
    if @project.user.admin?
      @project.state = "accepted"
    else
      @project.state = "pending"
    end

    respond_to do |format|
      if @project.save
        @project_team = @project.create_team(name: "Team#{@project.id}")
        TeamMembership.create(team_member_id: current_user.id, team_id: @project_team.id)
        activity = current_user.create_activity(@project, 'created')
        # activity.user_id = current_user.id
        chatroom =Chatroom.create(name: @project.title, project_id: @project.id)
        Groupmember.create(user_id: current_user.id, chatroom_id: chatroom.id)
        format.html { redirect_to @project, notice: 'Project request was sent.' }
        format.json { render json: {id: @project.id, status: 200, responseText: "Project has been Created Successfully "} }
        session[:project_id] = @project.id
      else
        format.html { render :new }
        format.json { render json: @project.errors.full_messages.to_sentence, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @project.update(project_params)
        activity = current_user.create_activity(@project, 'updated')
        activity.user_id = current_user.id
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def change_leader
    @project = Project.find params[:project_id]
    @email = params[:leader]["address"]
    if @project.change_leader_invitations.pending.any?
      flash[:notice] = "You have already invited a new leader for this project"
    elsif @email != current_user.email
      @invitation = @project.change_leader_invitations.create(new_leader: @email, sent_at: Time.current)
      InvitationMailer.invite_leader(@invitation.id).deliver_now
    end

    redirect_to :my_projects
  end

  # POST /save-edits
  # POST /save-edits.json
  def saveEdit
    @project_edit = @project.project_edits.create(description: edit_params[:project_edit])
    @project_edit.user = current_user
    puts @project_edit.description
    respond_to do |format|
      if @project_edit.save
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def updateEdit
    id_t = params[:project][:editItem][:id]
    new_state = params[:project][:editItem][:new_state]
    puts "id_t: " + id_t
    @project_edit = ProjectEdit.find_by(id: id_t)
    @project_edit.update(:aasm_state => new_state)
    puts @project_edit.description
    if new_state == "accepted"
      @project.description = @project_edit.description
      respond_to do |format|
        if @project.save
          format.html { redirect_to @project, notice: 'Project was successfully updated.' }
          format.json { render json: @project, status: :ok }
        else
          format.html { render :edit }
          format.json { render json: @project.errors, status: :unprocessable_entity }
        end
      end
    end

    if new_state == "rejected"
      respond_to do |format|
        if @project.save
          format.html { redirect_to @project, notice: 'Project was successfully updated.' }
          format.json { render json: @project, status: :ok }
        else
          format.html { render :edit }
          format.json { render json: @project.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def accept
    @project = Project.find(params[:id])
    if @project.accept!
      activity = current_user.create_activity(@project, 'accepted')
      activity.user_id = current_user.id
      @project.user.update_attribute(:role, 'manager');
      #Change all pending projects for user
      flash[:success] = "Project Request accepted"
    else
      flash[:error] = "Project could not be accepted"
    end
    redirect_to current_user
  end

  def reject
    @project = Project.find(params[:id])
    if @project.reject!
      activity = current_user.create_activity(@project, 'rejected')
      activity.user_id = current_user.id
      flash[:success] = "Project rejected"
    else
      flash[:error] = "Project could not be rejected"
    end
    redirect_to current_user
  end

  def read_from_mediawiki

    result = current_user.page_read @project.title
    @contents = ''
    if result
      if result["status"] == 'success'
        @contents = result['html'].html_safe.split("\n")
      else
        # Create new page
        current_user.page_write @project.title, ''
        result = current_user.page_read @project.title
        @contents = ''
      end
    else
      #TODO create new session for mediawiki
      @contents = ''
    end

    respond_to do |format|
      format.js
    end
  end

  def write_to_mediawiki
    if current_user.page_write @project.title, params[:data]
      result = current_user.page_read @project.title
      @contents = result["non-html"].html_safe.split("\n")
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    project = Project.find(params[:id])
    project.destroy
    respond_to do |format|
      activity = current_user.create_activity(@project, 'deleted')
      activity.user_id = current_user.id
      format.html { redirect_to :my_projects, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def featured
    @featured_projects = Project.get_featured_projects
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(
        :title, :short_description, :institution_country, :description, :country,
        :picture, :user_id, :institution_location, :state, :expires_at, :request_description,
        :institution_name, :institution_logo, :institution_description, :section1, :section2,
        :picture_crop_x, :picture_crop_y, :picture_crop_w, :picture_crop_h,
        project_edits_attributes: [:id, :_destroy, :description]
      )
    end

  def get_project_user
    @project_user = @project.user
  end

  def edit_params
    params.require(:project).permit(:id, :project_edit, :editItem)
  end
end
