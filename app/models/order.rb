class Order < ApplicationRecord
  belongs_to :user
  belongs_to :newspaper, optional: true

  enum :order_type, { one_off: 0, recurring: 1 }
  enum :frequency, { weekly: 0, monthly: 1, quarterly: 2 }
  enum :status, { pending: 0, generated: 1, dispatched: 2, printed: 3, shipped: 4, delivered: 5 }

  validates :page_count, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :delivery_address, presence: true
  validates :stripe_payment_id, presence: true
end
