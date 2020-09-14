class CitationsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 500
    @citations = Citation.reorder(created_at: :desc).includes(:publication)
      .page(page).per(per_page)
  end

  def show
    @citation = Citation.friendly_find!(params[:id])
    @hypotheses = @citation.hypotheses
  end

  def new
    @citation ||= Citation.new
  end

  def create
    @citation = Citation.new(permitted_citation_params)
    if @citation.save
      flash[:success] = "Citation created"
      redirect_to citations_path
    else
      render :new
    end
  end

  private

  def permitted_citation_params
    params.require(:citation)
      .permit(:title, :authors_str, :assignable_kind, :url,
        :url_is_direct_link_to_full_text, :published_at_str)
      .merge(creator: current_user)
  end
end
