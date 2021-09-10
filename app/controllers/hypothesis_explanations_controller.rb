class HypothesisExplanationsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_hypothesis_explanation
  before_action :ensure_user_can_edit!, only: %i[edit update]
  before_action :set_permitted_format

  def edit
    @page_title = "Edit Explanation: #{@hypothesis.title}"
  end

  def new
    @page_title = "Add Explanation: #{@hypothesis.title}"
    if @explanation.blank? # Just in case we're rendering again
      @explanation = @hypothesis.explanations.build
    end
  end

  def create
    @explanation = @hypothesis.explanations.build(permitted_params)
    @explanation.creator_id = current_user.id
    if @explanation.save
      update_hypothesis_if_permitted
      @explanation.update_body_html
      flash[:success] = "Explanation added!"
      redirect_to edit_hypothesis_explanation_path(id: @explanation.id, hypothesis_id: @hypothesis.ref_id)
    else
      render :new
    end
  end

  def update
    previous_explanation_quote_ids = @explanation.explanation_quotes.pluck(:id).map(&:to_s)
    update_successful = @explanation.update(permitted_params)
    if update_successful
      update_hypothesis_if_permitted
      @explanation.remove_empty_quotes!
      # Remove explanation_quotes that weren't included in the params (they were removed on the frontend)
      updated_quote_ids = permitted_params[:explanation_quotes_attributes]&.keys || []
      @explanation.explanation_quotes.where(id: previous_explanation_quote_ids - updated_quote_ids).destroy_all
      @explanation.update_body_html
      @explanation.reload # Because maybe things were deleted!
      update_citations_if_permitted
      # Manually trigger to ensure it happens after explanation is updated
      if ParamsNormalizer.boolean(params.dig(:explanation, :add_to_github)) && @explanation.validate_can_add_to_github?
        @explanation.update(add_to_github: true)
        flash[:success] = "Explanation submitted for review"
        redirect_to hypothesis_path(@hypothesis.ref_id, explanation_id: @explanation.ref_number)
      else
        if @explanation.errors.full_messages.any? # Happens when fail to submit to github
          flash[:error] = @explanation.errors.full_messages.join(", ")
        else
          flash[:success] = "Explanation saved"
        end
        target_url_params = {hypothesis_id: @hypothesis.ref_id, id: @explanation.id}
        # Don't include initially_toggled paramets unless it's passed because it's ugly
        target_url_params[:initially_toggled] = true if ParamsNormalizer.boolean(params[:initially_toggled])
        redirect_to edit_hypothesis_explanation_path(target_url_params)
      end
    else
      render :edit
    end
  end

  private

  # To make it possible to use the file path from a explanation directly
  def set_permitted_format
    request.format = "html" unless request.format == "json"
  end

  def find_hypothesis_explanation
    @hypothesis = Hypothesis.friendly_find!(params[:hypothesis_id])
    @explanation = Explanation.find_by_id(params[:id])
  end

  def ensure_user_can_edit!
    return true if @explanation.editable_by?(current_user)
    flash[:error] = flash[:error] = if @explanation.not_submitted_to_github?
                      "You can't edit that explanation because you didn't create it"
                    else
                      "You can't edit explanations that have been submitted"
                    end
    redirect_to hypothesis_path(@hypothesis)
    nil
  end

  def update_hypothesis_if_permitted
    return unless @hypothesis.editable_by?(current_user) &&
      (params[:hypothesis_title].present? || params[:hypothesis_tag_string].present?)

    @hypothesis.title = params[:hypothesis_title] if params[:hypothesis_title].present?
    @hypothesis.tags_string = params[:hypothesis_tags_string] if params[:hypothesis_tags_string]
    @hypothesis.save
  end

  def permitted_params
    params.require(:explanation).permit(:text,
      explanation_quotes_attributes: [:url, :text, :ref_number, :id, :removed])
  end

  def update_citations_if_permitted
    (permitted_citations_params || []).each do |_id, attrs|
      explanation_quote = @explanation.explanation_quotes.find_by_id(attrs[:explanation_quote_id])
      citation = explanation_quote&.citation
      citation.update!(attrs.except(:explanation_quote_id)) if citation&.editable_by?(current_user)
    end
  end

  # Get each set of permitted citation attributes. We're updating them individually
  def permitted_citations_params
    params.require(:explanation).permit(citations_attributes: Citation.permitted_attrs)
      .dig(:citations_attributes)
  end
end
