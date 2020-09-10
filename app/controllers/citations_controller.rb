class CitationsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: [:index]

  def index
    @citations = Citation.reorder(created_at: :desc)
  end

  def new
    @citation ||= Citation.new
  end

  def create
    @citation = Citation.new(permitted_params)
    if @citation.save
      flash[:success] = "Citation created!"
      redirect_back(fallback_location: citations_path)
    else
      @citation.errors.full_messages
      render :new
    end
  end

  private

  def permitted_params
    params.require(:citation).permit(:title, :authors_str, :publication_name, :assignable_kind,
                                     :url, :url_is_direct_link_to_full_text, :published_at_str)
      .merge(creator: current_user)
  end
end
