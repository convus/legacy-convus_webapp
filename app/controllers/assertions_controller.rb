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
    permitted_citation_params.each do |citation_attrs|
      @assertion.citations.build(citation_attrs.merge(creator: current_user))
    end
    if @assertion.save
      flash[:success] = "Assertion created!"
      redirect_back(fallback_location: assertions_path)
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
    citation_params = params.dig(:assertion, :citations_attributes)&.values
    return {} unless citation_params.present?
    citation_params.map { |c| c.slice(*permitted_citation_attrs) }
  end

  def permitted_citation_attrs
    %w[title authors_str publication_name assignable_kind url url_is_direct_link_to_full_text published_at_str]
  end
end
