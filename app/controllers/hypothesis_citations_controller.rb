class HypothesisCitationsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_hypothesis_citation
  before_action :ensure_user_can_edit!, only: %i[edit update]
  before_action :set_permitted_format

  def edit
    @page_title = "Edit - #{@hypothesis_citation.title}"
  end

  def new
    @page_title = "Add citation - #{@hypothesis.title}"
    if @hypothesis_citation.blank? # Just in case we're rendering again
      @hypothesis_citation = @hypothesis.hypothesis_citations.build
      if @challenged_hypothesis_citation.present?
        @hypothesis_citation.challenged_hypothesis_citation = @challenged_hypothesis_citation
        @hypothesis_citation.kind = HypothesisCitation.challenge_kinds.first
      end
    end
  end

  def create
    @hypothesis_citation = @hypothesis.hypothesis_citations.build(permitted_params)
    @hypothesis_citation.creator_id = current_user.id
    if @hypothesis_citation.save
      flash[:success] = "Citation added!"
      redirect_to edit_hypothesis_citation_path(id: @hypothesis_citation.id, hypothesis_id: @hypothesis.ref_id)
    else
      render :new
    end
  end

  def update
    update_successful = @hypothesis_citation.update(permitted_params)
    if update_successful && permitted_citation_params.present? &&
        @hypothesis_citation.citation.editable_by?(current_user)
      # Because the citation is assigned during creation, we can't use nested attributes to update it
      citation = @hypothesis_citation.citation
      update_successful = citation.update(permitted_citation_params)
      flash[:error] = "Couldn't save citation; #{citation.errors.full_messages}" unless update_successful
    end
    if update_successful
      # Manually trigger to ensure it happens after citation is updated
      if ParamsNormalizer.boolean(params.dig(:hypothesis_citation, :add_to_github))
        @hypothesis_citation.update(add_to_github: true)
      end
      if @hypothesis_citation.submitted_to_github?
        flash[:success] = "Citation submitted for review"
        redirect_to hypothesis_path(@hypothesis, hypothesis_citation_id: @hypothesis_citation.to_param)
      else
        flash[:success] = "Citation saved"
        target_url_params = {hypothesis_id: @hypothesis.ref_id, id: @hypothesis_citation.id}
        # Don't include initially_toggled paramets unless it's passed because it's ugly
        target_url_params[:initially_toggled] = true if ParamsNormalizer.boolean(params[:initially_toggled])
        redirect_to edit_hypothesis_citation_path(target_url_params)
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
    @hypothesis_citation = HypothesisCitation.find_by_id(params[:id])
    @hypothesis_citations_shown = @hypothesis.hypothesis_citations.approved

    if @hypothesis_citation&.challenge? || params[:challenged_hypothesis_citation_id].present?
      @challenged_hypothesis_citation = @hypothesis_citation&.challenged_hypothesis_citation
      @challenged_hypothesis_citation ||= @hypothesis.hypothesis_citations.find(params[:challenged_hypothesis_citation_id])
      @hypothesis_citations_shown = @hypothesis_citations_shown.where.not(id: @challenged_hypothesis_citation.id)
    end
  end

  def ensure_user_can_edit!
    return true if @hypothesis_citation.editable_by?(current_user)
    flash[:error] = flash[:error] = if @hypothesis_citation.not_submitted_to_github?
                      "You can't edit that citation because you didn't create it"
                    else
                      "You can't edit citations that have been submitted"
                    end
    redirect_to hypothesis_path(@hypothesis)
    nil
  end

  def permitted_params
    permitted_attrs = %i[url quotes_text]
    # Only can update these attrs on create:
    permitted_attrs += %i[kind challenged_hypothesis_citation_id] if @hypothesis_citation&.id.blank?
    params.require(:hypothesis_citation).permit(*permitted_attrs)
      .merge(creator_id: current_user.id)
  end

  def permitted_citation_params
    params.require(:hypothesis_citation).permit(citation_attributes:
      %i[title authors_str kind url_is_direct_link_to_full_text published_date_str
        url_is_not_publisher publication_title peer_reviewed randomized_controlled_trial quotes_text])
      .dig(:citation_attributes)
  end
end
