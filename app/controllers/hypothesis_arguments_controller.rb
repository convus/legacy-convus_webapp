class HypothesisArgumentsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_hypothesis_argument
  before_action :ensure_user_can_edit!, only: %i[edit update]
  before_action :set_permitted_format

  def edit
    @page_title = "Edit - #{@argument.display_id}"
  end

  def new
    @page_title = "Add Argument - #{@hypothesis.title}"
    if @argument.blank? # Just in case we're rendering again
      @argument = @hypothesis.arguments.build
    end
  end

  def create
    @argument = @hypothesis.arguments.build(permitted_params)
    @argument.creator_id = current_user.id
    if @argument.save
      flash[:success] = "Argument added!"
      redirect_to edit_hypothesis_argument_path(id: @argument.id, hypothesis_id: @hypothesis.id)
    else
      render :new
    end
  end

  def update
    update_successful = @argument.update(permitted_params)
    if update_successful
      # Manually trigger to ensure it happens after argument is updated
      if ParamsNormalizer.boolean(params.dig(:argument, :add_to_github))
        @argument.update(add_to_github: true)
      end
      if @argument.submitted_to_github?
        flash[:success] = "Argument submitted for review"
        redirect_to hypothesis_path(@hypothesis, argument_id: @argument.to_param)
      else
        flash[:success] = "Argument saved"
        target_url_params = {hypothesis_id: @hypothesis.id, id: @argument.id}
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

  def permitted_params
    params.require(:argument).permit(:text)
  end
end
