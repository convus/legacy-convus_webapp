class ArgumentQuote < ApplicationRecord
  belongs_to :argument
  belongs_to :citation
  belongs_to :creator, class_name: "User"

  before_validation :set_calculated_attributes

  def set_calculated_attributes
    self.url = UrlCleaner.with_http(UrlCleaner.without_utm(url))
    self.creator_id ||= argument.creator_id
    self.citation_id = Citation.find_or_create_by_params({url: url, creator_id: creator_id})&.id
  end
end
