class HypothesesController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]
  before_action :find_hypothesis, except: %i[index new create]
  before_action :set_permitted_format

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 500
    @hypotheses = matching_hypotheses.reorder(created_at: :desc)
      .page(page).per(per_page)
    @page_title = "Convus"
  end

  def show
  end

  def edit
  end

  def new
    @hypothesis ||= Hypothesis.new
  end

  def create
    @hypothesis = Hypothesis.new(permitted_params)
    citation = Citation.find_or_create_by_params(permitted_citation_params)
    @hypothesis.hypothesis_citations.build(citation: citation, quotes_text: citation&.quotes_text)
    if @hypothesis.save
      flash[:success] = "Hypothesis created!"
      redirect_to edit_hypothesis_path(@hypothesis.id)
    else
      @hypothesis.errors_full_messages
      render :new
    end
  end

  helper_method :matching_hypotheses

  private

  # To make it possible to use the file path from a citation directly
  def set_permitted_format
    request.format = "html" unless request.format == "json"
  end

  def find_hypothesis
    @hypothesis = Hypothesis.friendly_find!(params[:id])
    @citations = @hypothesis.citations
  end

  def matching_hypotheses
    hypotheses = params[:unapproved].present? ? Hypothesis.unapproved : Hypothesis.approved
    if params[:search_array].present?
      @search_tags = Tag.matching_tags(params[:search_array])
      hypotheses = hypotheses.with_tag_ids(@search_tags.pluck(:id))
    end
    hypotheses
  end

  def permitted_create_params
    params.require(:hypothesis).permit(:title, :add_to_github, :tags_string).merge(creator: current_user)
  end

  def permitted_params
    params.require(:hypothesis).permit(:title, :add_to_github, :tags_string).merge(creator: current_user)
  end

  def permitted_citation_params
    cparams = params.require(:hypothesis).permit(citations_attributes: permitted_citation_attrs)
      .dig(:citations_attributes)
    return cparams if cparams.blank? # NOTE: This shouldn't really happen because the HTML fields are required
    cparams.merge(creator: current_user)
  end

  def permitted_citation_attrs
    %w[title authors_str assignable_kind url url_is_direct_link_to_full_text published_date_str
      url_is_not_publisher publication_title peer_reviewed randomized_controlled_trial quotes_text]
  end
end
