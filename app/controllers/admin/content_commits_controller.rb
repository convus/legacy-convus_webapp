# frozen_string_literal: true

class Admin::ContentCommitsController < Admin::BaseController
  include SortableTable
  before_action :set_period, only: [:index]

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    @render_chart = ParamsNormalizer.boolean(params[:render_chart])
    @time_range_column = set_time_range_column
    @content_commits = matching_content_commits.reorder("#{sort_column} #{sort_direction}").page(page).per(per_page)
  end

  helper_method :matching_content_commits

  private

  def sortable_columns
    %w[committed_at id created_at updated_at author]
  end

  def set_time_range_column
    if sort_column == "created_at"
      "created_at"
    elsif sort_column == "updated_at"
      "updated_at"
    else # Defaults to committed_at
      "committed_at"
    end
  end

  def matching_content_commits
    content_commits = ContentCommit

    content_commits.where(@time_range_column => @time_range)
  end
end
