module FriendlyFindable
  extend ActiveSupport::Concern

  module ClassMethods
    def friendly_find_id(str = nil)
      o = friendly_find(str)
      o.present? ? o.id : nil
    end

    def friendly_find_slug(str = nil)
      find_by_slug(Slugifyer.slugify(str)) || find_by_slug(Slugifyer.filename_slugify(str))
    end

    def friendly_find(str = nil)
      return nil unless str.present?
      integer_slug?(str) ? find_by_id(str) : friendly_find_slug(str)
    end

    def friendly_find!(str = nil)
      friendly_find(str) || (raise ActiveRecord::RecordNotFound)
    end

    def integer_slug?(str = nil)
      str.is_a?(Integer) || str.to_s.strip.match(/\A\d*\z/).present?
    end
  end
end
