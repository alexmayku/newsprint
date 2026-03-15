class Newspaper < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :newsletters
  has_many :all_articles, through: :newsletters, source: :articles
  has_many :orders
  has_one_attached :pdf

  enum :status, { draft: 0, generating: 1, generated: 2, failed: 3 }

  before_create :set_edition_number
  before_create :set_default_title

  private

  def set_edition_number
    self.edition_number = user.newspapers.count + 1
  end

  def set_default_title
    self.title = "My Newsprint — #{Date.current.strftime('%B %-d, %Y')}" if title.blank?
  end
end
