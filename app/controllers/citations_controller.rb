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
    params.require(:citation).permit(:title, :authors_str, :publication_name, :assignable_kind, :url)
      .merge(creator: current_user, published_at: calculated_published_at)
  end

  def calculated_published_at
    time = TimeParser.parse(params.dig(:citation, :published_at))
    time.blank? ? time : time.beginning_of_day
  end
end
