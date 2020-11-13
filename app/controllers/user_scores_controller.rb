class UserScoresController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  def create
    @hypothesis = Hypothesis.friendly_find!(params[:hypothesis_id])
    current_user.user_scores.create(hypothesis_id: params[:hypothesis_id],
                                    score: params[:score],
                                    kind: params[:kind])
    redirect_back(fallback_location: hypothesis_path(@hypothesis.to_param))
  end
end
