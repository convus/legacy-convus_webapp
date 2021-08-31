class HypothesisArgumentsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_hypothesis_argument
  before_action :ensure_user_can_edit!, only: %i[edit update]
  before_action :set_permitted_format

  def edit
    @page_title = "Edit Argument: #{@hypothesis.title}"
  end

  def new
    @page_title = "Add Argument: #{@hypothesis.title}"
    if @argument.blank? # Just in case we're rendering again
      @argument = @hypothesis.arguments.build
    end
  end

  def create
    @argument = @hypothesis.arguments.build(permitted_params)
    @argument.creator_id = current_user.id
    if @argument.save
      update_hypothesis_if_permitted
      @argument.update_body_html
      flash[:success] = "Argument added!"
      redirect_to edit_hypothesis_argument_path(id: @argument.id, hypothesis_id: @hypothesis.ref_id)
    else
      render :new
    end
  end

  def update
    previous_argument_quote_ids = @argument.argument_quotes.pluck(:id).map(&:to_s)
    update_successful = @argument.update(permitted_params)
    if update_successful
      update_hypothesis_if_permitted
      @argument.remove_empty_quotes!
      # Remove argument_quotes that weren't included in the params (they were removed on the frontend)
      updated_quote_ids = permitted_params[:argument_quotes_attributes]&.keys || []
      @argument.argument_quotes.where(id: previous_argument_quote_ids - updated_quote_ids).destroy_all
      @argument.update_body_html
      @argument.reload # Because maybe things were deleted!
      # Manually trigger to ensure it happens after argument is updated
      if ParamsNormalizer.boolean(params.dig(:argument, :add_to_github)) && @argument.validate_can_add_to_github?
        @argument.update(add_to_github: true)
        flash[:success] = "Argument submitted for review"
        redirect_to hypothesis_path(@hypothesis.ref_id, argument_id: @argument.ref_number)
      else
        if @argument.errors.full_messages.any? # Happens when fail to submit to github
          flash[:error] = @argument.errors.full_messages.join(", ")
        else
          flash[:success] = "Argument saved"
        end
        target_url_params = {hypothesis_id: @hypothesis.ref_id, id: @argument.id}
        # Don't include initially_toggled paramets unless it's passed because it's ugly
        target_url_params[:initially_toggled] = true if ParamsNormalizer.boolean(params[:initially_toggled])
        redirect_to edit_hypothesis_argument_path(target_url_params)
      end
    else
      render :edit
    end
  end

  private

  # To make it possible to use the file path from a argument directly
  def set_permitted_format
    request.format = "html" unless request.format == "json"
  end

  def find_hypothesis_argument
    @hypothesis = Hypothesis.friendly_find!(params[:hypothesis_id])
    @argument = Argument.find_by_id(params[:id])
    @hypothesis_citations_shown = @hypothesis.hypothesis_citations.shown(current_user)
  end

  def ensure_user_can_edit!
    return true if @argument.editable_by?(current_user)
    flash[:error] = flash[:error] = if @argument.not_submitted_to_github?
                      "You can't edit that argument because you didn't create it"
                    else
                      "You can't edit arguments that have been submitted"
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
    params.require(:argument).permit(:text,
      argument_quotes_attributes: [:url, :text, :ref_number, :id, :removed])
  end
end
