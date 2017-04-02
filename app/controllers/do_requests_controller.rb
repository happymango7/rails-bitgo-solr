class DoRequestsController < ApplicationController
  before_filter :authenticate_user!

  def index
  end

  def new
    @task = Task.find(params[:task_id])
    if @task.suggested_task?
      flash[:error] = "You can not Apply For Suggested Task "
      redirect_to task_path(@task.id)
    end
    @free = params[:free]
    @do_request = DoRequest.new
  end

  def create
    @do_request = current_user.do_requests.build(request_params) rescue nil
    task=Task.find (request_params['task_id'])
    if task.suggested_task?
      flash[:error] = "You can not Apply For Suggested Task "
      redirect_to task_path(task.id)
    end
    @do_request.project_id = task.project_id
    if current_user.id == task.project.user_id
      @do_request.state='accepted'
    else
      @do_request.state='pending'
    end
    respond_to do |format|
      if @do_request.save
        @msg="Request sent to Project Admin";
        if current_user.id == task.project.user_id
          @msg="You become Member of This Task team";
        end
        flash[:success] = @msg
        format.html { redirect_to @do_request.task, notice: 'Request sent to Project Admin.' }
        format.json { render json: {id: @do_request, status: 200, responseText: "Request sent to Project Admin "} }
        format.js
      else
        @msg="You can not Apply Twice";
        format.html { redirect_to root_url, notice: "You can not Apply Twice" }
        format.js
      end
    end
  end

  def update
  end

  def destroy
    @do_request = DoRequest.find(params[:id])
    @do_request.destroy
    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: 'Task assignment request was successfully destroyed.' }
      format.json { head :no_content }
    end

  end

  def accept
    @do_request = DoRequest.find(params[:id])
    if current_user.id == @do_request.task.project.user_id
      if @do_request.accept!
        @do_request.user.assign(@do_request.task, @do_request.free)
        @current_number_of_participants = @do_request.task.try(:number_of_participants) || 0
        @do_request.task.update_attribute(:deadline, @do_request.task.created_at + 60.days)
        @do_request.task.update_attribute(:number_of_participants, @current_number_of_participants + 1)
        team = Team.find_or_create_by(project_id: @do_request.project_id)
        TeamMembership.create(team_member_id: @do_request.user_id, team_id: team.id, task_id: @do_request.task_id, state: "user")
        Groupmember.create(user_id: @do_request.user_id, chatroom_id: team.project.chatroom.id)
        flash[:success] = "Task has been assigned"
      else
        flash[:error] = "Task was not assigned to user"
      end
    else
      flash[:error] = "You Are Not Authorized User"
    end
    redirect_to @do_request.task
  end

  def reject
    @do_request = DoRequest.find(params[:id])
    if current_user.id == @do_request.task.project.user_id
      if @do_request.reject!
        flash[:succes] = "Request rejected"
      else
        flash[:error] = "Was not able to reject request"
      end
    else
      flash[:error] = "You Are Not Authorized User"
    end
    redirect_to @do_request.task
  end

  private

  def request_params
    params.require(:do_request).permit(:application, :task_id, :user_id, :free)
  end

end
