class PreviousTitle < ApplicationRecord
  include TitleSluggable
  belongs_to :hypothesis

  validate :stored_title_update

  scope :id_ordered, -> { reorder(:id) }

  def self.validate_title_uniqueness
    false
  end

  # non-singular duplicate of #friendly_find_slug
  def self.matching_slug(str = nil)
    full_slug_match = where(slug: Slugifyer.slugify(str))
    if full_slug_match.any?
      full_slug_match
    else
      where(slug: Slugifyer.filename_slugify(str))
    end.id_ordered
  end

  def hypothesis_previous_titles
    self.class.where(hypothesis_id: hypothesis_id).id_ordered
  end

  def last_previous_title
    hypothesis_previous_titles.last
  end

  def stored_title_update
    return true if id.present?
    if last_previous_title&.slug == slug || hypothesis.slug == slug
      errors.add(:title, "Slug didn't change from previous title")
    end
  end
end
