# frozen_string_literal: true

class StaticController < ApplicationController
  def about
    @page_title = "About Convus"
  end

  def editing
    @page_title = "Editing"
  end
end
