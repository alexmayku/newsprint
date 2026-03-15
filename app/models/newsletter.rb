class Newsletter < ApplicationRecord
  belongs_to :user
  has_many :articles, dependent: :destroy

  validates :sender_email, presence: true
  validates :title, presence: true
  validates :est_pages, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :latest_issue_date, presence: true
end
