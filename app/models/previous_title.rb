class PreviousTitle < ApplicationRecord
  belongs_to :hypothesis

  before_validation :set_slug # We don't want to validate uniqueness, so handle separately from TitleSluggable

  validate :stored_title_updates

  scope :id_ordered, -> { reorder(:id) }

  def self.validate_title_uniqueness
    false
  end

  # non-singular duplicate of #friendly_find_slug
  def self.friendly_matching(str = nil)
    full_title_match = where("previous_titles.title ILIKE ?", str.to_s)
    if full_title_match.any?
      full_title_match
    else
      where(slug: Slugifyer.filename_slugify(str))
    end.joins(:hypothesis).id_ordered
  end

  def hypothesis_previous_titles
    self.class.where(hypothesis_id: hypothesis_id).id_ordered
  end

  def last_previous_title
    hypothesis_previous_titles.last
  end

  def set_slug
    self.slug = Slugifyer.filename_slugify(title)
  end

  def stored_title_updates
    return true if id.present?
    if title.blank?
      errors.add(:title, "Can't be blank")
    elsif last_previous_title&.slug == slug || hypothesis.slug == slug
      errors.add(:title, "Slug didn't change from previous title")
    end
  end
end
