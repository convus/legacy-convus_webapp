class HypothesesController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]
  before_action :process_user_score
  before_action :find_hypothesis, except: %i[index new create]
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
    @page_title = "REFUTED: #{@page_title}" if @hypothesis.refuted?
  end

  def edit
    @page_title = "Edit - #{@hypothesis.title}"
  end

  def new
    @hypothesis ||= Hypothesis.new
  end

  def create
    @hypothesis = Hypothesis.new(permitted_params)
    @hypothesis.creator_id = current_user.id
    if @hypothesis.save
      flash[:success] = "Hypothesis created!"
      redirect_to edit_hypothesis_path(@hypothesis.id)
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

  def process_user_score
    return true if session[:after_sign_in_score].blank? || current_user.blank?
    new_score_data = session.delete(:after_sign_in_score)
    hypothesis_id, score, kind = new_score_data.split(",")
    return true if [hypothesis_id, score, kind].compact.count < 3
    new_score = current_user.user_scores.new(hypothesis_id: hypothesis_id, kind: kind, score: score)
    new_score.set_calculated_attributes
    most_recent_score = current_user.user_scores.current.where(hypothesis_id: hypothesis_id, kind: kind).last
    return true if most_recent_score&.score == new_score.score
    new_score.save
  end

  def ensure_user_can_edit!
    return true if @hypothesis.editable_by?(current_user)
    flash[:error] = if @hypothesis.not_submitted_to_github?
      "You can't edit that hypothesis because you didn't create it"
    else
      "You can't edit hypotheses that have been submitted"
    end
    redirect_to hypothesis_path(@hypothesis)
    nil
  end

  def matching_hypotheses
    return @matching_hypotheses if defined?(@matching_hypotheses)
    hypotheses = ParamsNormalizer.boolean(params[:search_unapproved]) ? Hypothesis.unapproved : Hypothesis.approved
    hypotheses = ParamsNormalizer.boolean(params[:search_refuted]) ? hypotheses.refuted : hypotheses.unrefuted

    if params[:search_array].present?
      matches = Tag.matching_tag_ids_and_non_tags(params[:search_array])
      @search_tags = Tag.where(id: matches[:tag_ids])
      hypotheses = hypotheses.with_tag_ids(@search_tags.pluck(:id)) if @search_tags.any?
      hypotheses = hypotheses.text_search(matches[:non_tags]) if matches[:non_tags].any?
      @search_items = @search_tags.pluck(:title) + matches[:non_tags]
    else
      @search_items = []
    end

    @matching_hypotheses = hypotheses
  end

  def permitted_params
    # Permit tags_string as a string or an array
    params.require(:hypothesis).permit(:title, :add_to_github, :tags_string, tags_string: [],
                                                                             hypothesis_citations_attributes: [:url, :quotes_text, :_destroy, :id])
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
