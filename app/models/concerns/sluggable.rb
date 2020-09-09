module Sluggable
  extend ActiveSupport::Concern
  included do
    before_validation :set_slug
    validates :title, presence: true, uniqueness: true, if: :requires_title?
    validates :slug, uniqueness: true, if: :requires_title?
  end

  module ClassMethods
    def friendly_find_id(str = nil)
      o = friendly_find(str)
      o.present? ? o.id : nil
    end

    def friendly_find_slug(str = nil)
      find_by_slug(Slugifyer.slugify(str))
    end

    def friendly_find(str = nil)
      return nil unless str.present?
      integer_slug?(str) ? find(str) : friendly_find_slug(str)
    end

    def friendly_find!(str = nil)
      friendly_find(str) || (raise ActiveRecord::RecordNotFound)
    end

    def integer_slug?(str = nil)
      str.is_a?(Integer) || str.to_s.strip.match(/\A\d*\z/).present?
    end
  end

  def set_slug
    self.slug = Slugifyer.slugify(title)
  end

  # To make requiring title overrideable
  def requires_title?
    true
  end

  # Because we generally want this
  def to_param
    slug
  end
end
