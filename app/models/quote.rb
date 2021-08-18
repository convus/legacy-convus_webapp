class Quote < ApplicationRecord
  include ReferenceIdable

  belongs_to :citation
  has_many :hypothesis_quotes

  validates :text, presence: true, uniqueness: {scope: [:citation_id]}

  before_validation :set_calculated_attributes

  # May become more sophisticated in the future...
  def self.normalize(str)
    str.present? ? str&.strip : nil
  end

  # May become more sophisticated, e.g. capitalization, in the future
  def self.friendly_find(str)
    return none unless str.present?
    order(:created_at).where(text: str).first
  end

  def set_calculated_attributes
    self.text = Quote.normalize(text)
  end
end
