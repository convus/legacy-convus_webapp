class HypothesesController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]
  before_action :set_permitted_format

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 500
    @hypotheses = matching_hypotheses.reorder(created_at: :desc)
      .page(page).per(per_page)
    @page_title = "Convus"
  end

  def show
    @hypothesis = Hypothesis.friendly_find!(params[:id])
    @citations = @hypothesis.citations
  end

  def new
    @hypothesis ||= Hypothesis.new
  end

  def create
    @hypothesis = Hypothesis.new(permitted_params)
    citation = Citation.find_or_create_by_params(permitted_citation_params)
    @hypothesis.citations << citation if citation.present?
    if @hypothesis.save
      flash[:success] = "Hypothesis created!"
      redirect_to hypothesis_path(@hypothesis.to_param)
    else
      @hypothesis.errors.full_messages
      render :new
    end
  end

  helper_method :matching_hypotheses

  private

  # To make it possible to use the file path from a citation directly
  def set_permitted_format
    request.format = "html" unless request.format == "json"
  end

  def matching_hypotheses
    hypotheses = Hypothesis.approved
    if params[:search_array].present?
      @search_tags = Tag.matching_tags(params[:search_array])
      hypotheses = hypotheses.with_tag_ids(@search_tags.pluck(:id))
    end
    hypotheses
  end

  def permitted_params
    params.require(:hypothesis).permit(:title, :has_direct_quotation, :tags_string).merge(creator: current_user)
  end

  def permitted_citation_params
    cparams = params.require(:hypothesis).permit(citations_attributes: permitted_citation_attrs)
      .dig(:citations_attributes)
    return cparams if cparams.blank? # NOTE: This shouldn't really happen because the HTML fields are required
    cparams.merge(creator: current_user, skip_add_citation_to_github: true)
  end

  def permitted_citation_attrs
    %w[title authors_str assignable_kind url url_is_direct_link_to_full_text published_date_str
      url_is_not_publisher publication_title]
  end
end
