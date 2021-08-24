class ArgumentQuote < ApplicationRecord
  belongs_to :argument
  belongs_to :citation
  belongs_to :creator, class_name: "User"

  before_validation :set_calculated_attributes

  scope :ref_ordered, -> { reorder(:ref_number) }
  scope :removed, -> { where(removed: true) }
  scope :not_removed, -> { where(removed: false) }

  def ref_number_display
    ref_number + 1 # Off by 1
  end

  def removed?
    removed
  end

  def not_removed?
    !removed?
  end

  def set_calculated_attributes
    self.url = UrlCleaner.with_http(UrlCleaner.without_utm(url))
    self.creator_id ||= argument.creator_id
    self.citation_id = Citation.find_or_create_by_params({url: url, creator_id: creator_id})&.id
    # make sure ref_number is set, or things break
    self.ref_number ||= (argument&.argument_quotes&.maximum(:ref_number) || 0) + 1
  end
end
