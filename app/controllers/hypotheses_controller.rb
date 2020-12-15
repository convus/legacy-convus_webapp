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
        redirect_to edit_hypothesis_path(@hypothesis.id)
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
    if @hypothesis.not_submitted_to_github?
      return true if @hypothesis.creator == current_user
      flash[:error] = "You can't edit that hypothesis because you didn't create it"
    else
      flash[:error] = "You can't edit hypotheses that have been submitted"
    end
    redirect_to user_root_path
    nil
  end

  def matching_hypotheses
    hypotheses = ParamsNormalizer.boolean(params[:search_unapproved]) ? Hypothesis.unapproved : Hypothesis.approved
    hypotheses = ParamsNormalizer.boolean(params[:search_refuted]) ? hypotheses.refuted : hypotheses.unrefuted
    if params[:search_array].present?
      @search_tags = Tag.matching_tags(params[:search_array])
      hypotheses = hypotheses.with_tag_ids(@search_tags.pluck(:id))
    end
    hypotheses
  end

  def permitted_params
    params.require(:hypothesis).permit(:title, :add_to_github, :tags_string,
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
    %w[title authors_str assignable_kind url_is_direct_link_to_full_text published_date_str
      url_is_not_publisher publication_title peer_reviewed randomized_controlled_trial quotes_text]
  end
end
