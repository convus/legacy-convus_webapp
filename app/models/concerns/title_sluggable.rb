module TitleSluggable
  extend ActiveSupport::Concern
  include FriendlyFindable

  included do
    before_validation :set_slug
    validates :title, presence: true, uniqueness: true
    validates :slug, uniqueness: true
  end

  def set_slug
    self.slug = Slugifyer.slugify(title)
  end

  # All title slugs want this
  def to_param
    slug
  end
end
