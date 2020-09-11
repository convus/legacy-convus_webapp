class AssertionsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: [:index]

  def index
    @assertions = Assertion.reorder(created_at: :desc)
  end

  def new
    @assertion ||= Assertion.new
  end

  def create
    @assertion = Assertion.new(permitted_params)
    if permitted_citation_params.present?
      citation = Citation.find_or_create_by_params(permitted_citation_params.merge(creator: current_user))
      @assertion.citations << citation
    end
    if @assertion.save
      flash[:success] = "Assertion created!"
      redirect_to assertions_path
    else
      @assertion.errors.full_messages
      render :new
    end
  end

  private

  def permitted_params
    params.require(:assertion).permit(:title, :has_direct_quotation).merge(creator: current_user)
  end

  def permitted_citation_params
    params.require(:assertion).permit(citations_attributes: permitted_citation_attrs)
      .dig(:citations_attributes)
  end

  def permitted_citation_attrs
    %w[title authors_str assignable_kind url url_is_direct_link_to_full_text published_at_str]
  end
end
