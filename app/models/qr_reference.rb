class QrReference < ApplicationRecord
  belongs_to :article

  validates :url, presence: true
  validates :reference_number, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :label, presence: true
end
