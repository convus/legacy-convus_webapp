class PublicationsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 500
    @publications = Publication.reorder(created_at: :desc).includes(:citations)
      .page(page).per(per_page)
  end

  def show
    @publication = Publication.friendly_find!(params[:id])
    @citations = @publication.citations
  end
end
