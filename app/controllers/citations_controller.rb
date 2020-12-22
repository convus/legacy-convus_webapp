class CitationsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]
  before_action :set_permitted_format

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 500
    @citations = Citation.approved.reorder(created_at: :desc).includes(:publication)
      .page(page).per(per_page)
  end

  def show
    slug = [params[:publication_id], params[:id]].reject(&:blank?).join("-")
    @citation = Citation.friendly_find!(slug)
    @hypotheses = @citation.hypotheses.reorder(created_at: :desc)
    @page_title = @citation.display_title
  end

  private

  # To make it possible to use the file path from a citation directly
  def set_permitted_format
    request.format = "html" unless request.format == "json"
  end
end
