class HypothesesController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 500
    @hypotheses = Hypothesis.reorder(created_at: :desc)
      .page(page).per(per_page)
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
    if permitted_citation_params.present?
      citation = Citation.find_or_create_by_params(permitted_citation_params.merge(creator: current_user))
      @hypothesis.citations << citation
    end
    if @hypothesis.save
      flash[:success] = "Hypothesis created!"
      redirect_to hypotheses_path
    else
      @hypothesis.errors.full_messages
      render :new
    end
  end

  private

  def permitted_params
    params.require(:hypothesis).permit(:title, :has_direct_quotation, :family_tag_id).merge(creator: current_user)
  end

  def permitted_citation_params
    params.require(:hypothesis).permit(citations_attributes: permitted_citation_attrs)
      .dig(:citations_attributes)
  end

  def permitted_citation_attrs
    %w[title authors_str assignable_kind url url_is_direct_link_to_full_text published_at_str]
  end
end
