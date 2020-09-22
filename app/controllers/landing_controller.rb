# frozen_string_literal: true

class LandingController < ApplicationController
  def index
    @hypotheses = Hypothesis.approved.reorder(created_at: :desc)
  end
end
