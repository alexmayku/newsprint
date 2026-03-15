class Article < ApplicationRecord
  belongs_to :newsletter
  has_many :qr_references, dependent: :destroy

  validates :title, presence: true
  validates :body_html, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
end
