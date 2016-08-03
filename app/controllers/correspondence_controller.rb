class CorrespondenceController < ApplicationController

  def index
    @correspondence = Correspondence.all
  end

  def edit
    @correspondence = Correspondence.find(params[:id])
    render :edit
  end

  def update
    @correspondence = Correspondence.find(params[:id])

    if @correspondence.update(correspondence_params)
      flash[:notice] = "Correspondence assigned to #{@correspondence.drafter.email}" if assignation_params_present?
      render :edit
    else
      render :edit
    end
  end

  def search
    @correspondence = Correspondence.search(params[:search])
    render :index
  end

  private

  def correspondence_params
    params.require(:correspondence).permit(
        :category,
        :topic,
        :user_id
      )
  end

  def assignation_params_present?
    correspondence_params[:user_id].present?
  end

end
