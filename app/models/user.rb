class User < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  encrypts :google_token_enc
end
