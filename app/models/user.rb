class User < ApplicationRecord
  has_many :newsletters, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  encrypts :google_token_enc
end
