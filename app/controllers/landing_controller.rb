# frozen_string_literal: true

class LandingController < ApplicationController
  def index
    @assertions = Assertion.reorder(created_at: :desc)
  end
end
