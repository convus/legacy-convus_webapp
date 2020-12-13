module TitleSluggable
  extend ActiveSupport::Concern
  include FriendlyFindable

  included do
    before_validation :set_slug
    validates :title, presence: true, uniqueness: validate_title_uniqueness
    validates :slug, uniqueness: validate_title_uniqueness
  end

  module ClassMethods
    def validate_title_uniqueness
      true
    end
  end

  def set_slug
    self.slug = Slugifyer.filename_slugify(title)
  end

  # All title slugs want this
  def to_param
    slug
  end
end
