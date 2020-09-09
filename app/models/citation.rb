# t.references :publisher
# t.text :title
# t.text :slug
# t.json :authors
# t.datetime :published_at
# t.integer :kind
# t.text :url
# t.text :archive_link
# t.references :creator

class Citation < ApplicationRecord
  KIND_ENUM = {
    article: 0,
    not_public_access_research: 1,
    article_by_publisher_with_retractions: 2,
    quote_from_involved_party: 3,
    open_access_peer_reviewed: 4
  }.freeze

  belongs_to :publication
  belongs_to :creator, class_name: "User"

  has_many :assertion_citations
  has_many :assertions, through: :assertion_citations

  enum kind: KIND_ENUM

  def self.kinds_data
    {
      article: {score: 1, humanized: "Article"},
      not_public_access_research: {score: 2, humanized: "Non-public access research (anything than can not be accessed directly via a URL)"},
      article_by_publisher_with_retractions: {score: 3, humanized: "Article from a publisher which has issued retractions"},
      quote_from_involved_party: {score: 10, humanized: "Online accessible quote from applicable person (e.g. personal website, tweet, or video)"},
      open_access_peer_reviewed: {score: 20, humanized: "Peer reviewed open access study"}
    }.freeze
  end

  def self.humanized_kinds
    {
      article: "Article",
      not_public_access_research: 1
    }
  end

  def self.kinds
    KIND_ENUM.keys.map(&:to_s)
  end

  def kind_data
    kind.present? && self.class.kinds_data.dig(kind.to_sym) || {}
  end

  def kind_humanized
    kind_data[:humanized]
  end

  def kind_score
    kind_data[:score]
  end

  def set_calculated_attributes
    self.kind = calculated_article_kind if %[article article_by_publisher_with_retractions].include?(kind)
  end

  private

  def calculated_article_kind
    publication&.issued_retractions? ? "article_by_publisher_with_retractions" : "article"
  end
end
