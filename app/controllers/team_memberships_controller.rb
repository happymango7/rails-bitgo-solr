class TeamMembershipsController < ApplicationController
  load_and_authorize_resource

  def update
    @team_membership = TeamMembership.find(params[:id])

    respond_to do |format|
      if @team_membership.update(update_params)
        format.json { respond_with_bip(@team_membership) }
      else
        format.json { respond_with_bip(@team_membership) }
      end
    end
  end

  def destroy
    @team_membership = TeamMembership.find(params[:id])
    respond_to do |format|
      if @team_membership.destroy
        format.json { render json: @team_membership.id, status: :ok }
      else
        format.json { render status: :internal_server_error }
      end
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def update_params
      params.require(:team_membership).permit(:role)
    end
end
