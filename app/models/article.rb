class Article < ApplicationRecord
  belongs_to :newsletter

  validates :title, presence: true
  validates :body_html, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
end
