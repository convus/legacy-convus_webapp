class HypothesesController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]
  before_action :process_user_score
  before_action :find_hypothesis, except: %i[index new create]
  before_action :ensure_user_can_edit!, only: %i[edit update]
  before_action :set_permitted_format

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 500
    @hypotheses = matching_hypotheses.newness_ordered.page(page).per(per_page)
    @page_title = "Convus"
  end

  def show
    @page_title = @hypothesis.title
    if params[:explanation_id].present?
      explanation = @hypothesis.explanations.find_by_ref_number(params[:explanation_id])
      if explanation.blank?
        flash[:error] = "Unable to find that explanation"
      elsif explanation.approved?
        flash[:success] = "Explanation has been approved and is included on this page"
      else
        @unapproved_explanations = @hypothesis.explanations.where(ref_number: params[:explanation_id])
      end
    end
    @explanations = @hypothesis.explanations.approved
    @hypotheses_relations = @hypothesis.relations.shown(current_user)
    @unapproved_explanations ||= @hypothesis.explanations.unapproved.shown(current_user)
      .order(updated_at: :desc)
  end

  def new
    @hypothesis ||= Hypothesis.new
    if params[:related_hypothesis_id].present?
      @hypothesis_related = Hypothesis.friendly_find(params[:related_hypothesis_id])
      @hypothesis_related_kind = params[:related_kind] if HypothesisRelation.kinds.include?(params[:related_kind])
    end
  end

  def create
    @hypothesis = Hypothesis.new(permitted_params)
    @hypothesis.creator_id = current_user.id
    if @hypothesis.save
      update_hypothesis_relation(params[:hypothesis_relation_kind], params[:hypothesis_relation_id])
      flash[:success] = "Hypothesis created!"
      redirect_to new_hypothesis_explanation_path(hypothesis_id: @hypothesis.ref_id)
    else
      render :new
    end
  end

  helper_method :matching_hypotheses

  private

  # To make it possible to use the file path from a hypothesis directly
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
    params.require(:hypothesis).permit(:title, :add_to_github, :tags_string, tags_string: [])
  end

  # Duplicated in HypothesesExplanationController
  def update_hypothesis_relation(kind, id)
    other_hypothesis = Hypothesis.find_by_id(id)
    return nil unless other_hypothesis.present? && HypothesisRelation.kinds.include?(kind)
    HypothesisRelation.find_or_create_for(kind: kind,
      hypotheses: [@hypothesis, other_hypothesis],
      creator: current_user)
    @hypothesis.reload # Make sure the hypothesis comes along too
  end
end
