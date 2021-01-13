class HypothesisCitationsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_hypothesis_citation
  before_action :ensure_user_can_edit!, only: %i[edit update]
  before_action :set_permitted_format

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 500
    @hypotheses = matching_hypotheses.reorder(created_at: :desc)
      .page(page).per(per_page)
    @page_title = "Convus"
  end

  def show
    @page_title = @hypothesis.title
  end

  def edit
    @page_title = "Edit - #{@hypothesis.title}"
  end

  def new
    @hypothesis ||= Hypothesis.new
  end

  def create
    @hypothesis_citation = @hypothesis.hypothesis_citations.build(permitted_params)
    @hypothesis_citation.creator_id = current_user.id
    if @hypothesis_citation.save
      flash[:success] = "Hypothesis created!"
      redirect_to edit_hypothesis_citation_path(id: @hypothesis_citation.id, hypothesis_id: @hypothesis.id)
    else
      render :new
    end
  end

  def update
    if @hypothesis.update(permitted_params)
      @hypothesis.hypothesis_citations.each { |hc| update_citation(hc) }
      if @hypothesis.submitted_to_github?
        flash[:success] = "Hypothesis submitted for review"
        redirect_to hypothesis_path(@hypothesis.id)
      else
        flash[:success] = "Hypothesis saved"
        # Don't include initially_toggled paramets unless it's passed because it's ugly
        target_url_redirecting = ParamsNormalizer.boolean(params[:initially_toggled]) ? edit_hypothesis_path(@hypothesis.id, initially_toggled: true) : edit_hypothesis_path(@hypothesis.id)
        redirect_to target_url_redirecting
      end
    else
      render :edit
    end
  end

  private

  # To make it possible to use the file path from a citation directly
  def set_permitted_format
    request.format = "html" unless request.format == "json"
  end

  def find_hypothesis_citation
    @hypothesis = Hypothesis.friendly_find!(params[:hypothesis_id])
    hypothesis_citation_id = params[:id] || params[:hypothesis_citation_id] # necessary for challenges, probably
    if hypothesis_citation_id.present?
      @hypothesis_citation = HypothesisCitation.find(hypothesis_citation_id)
    end
  end

  def ensure_user_can_edit!
    return true if @hypothesis_citation.editable_by?(current_user)
    flash[:error] = if @hypothesis_citation.not_submitted_to_github?
      flash[:error] = "You can't edit that citation because you didn't create it"
    else
      flash[:error] = "You can't edit citations that have been submitted"
    end
    redirect_to hypothesis_path(@hypothesis)
    nil
  end

  def permitted_params
    # Permit tags_string as a string or an array
    params.require(:hypothesis_citation).permit(:url, :quotes_text, :add_to_github)
  end

  def update_citation(hypothesis_citation)
    return false unless hypothesis_citation.citation.editable_by?(current_user)
    hypothesis_citations_params = permitted_citations_params.values.find { |params|
      params.present? && params[:url] == hypothesis_citation.url
    }
    citation_params = hypothesis_citations_params&.dig(:citation_attributes)
    hypothesis_citation.citation.update(citation_params) if citation_params.present?
    hypothesis_citation.citation
  end

  # Get each set of permitted citation attributes. We're updating them individually
  def permitted_citations_params
    params.require(:hypothesis).permit(hypothesis_citations_attributes: [:url, {citation_attributes: permitted_citation_attrs}])
      .dig(:hypothesis_citations_attributes)
  end

  def permitted_citation_attrs
    %w[title authors_str kind url_is_direct_link_to_full_text published_date_str
      url_is_not_publisher publication_title peer_reviewed randomized_controlled_trial quotes_text]
  end
end
