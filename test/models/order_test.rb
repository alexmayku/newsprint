require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "order-user@example.com")
  end

  def valid_attrs(overrides = {})
    {
      user: @user,
      order_type: :one_off,
      page_count: 8,
      stripe_payment_id: "pi_test_123",
      delivery_address: { "line1" => "123 Main St", "city" => "London", "postcode" => "SW1A 1AA", "country" => "GB" },
      newsletter_ids: [ 1, 2, 3 ]
    }.merge(overrides)
  end

  test "order with all required fields is valid" do
    order = Order.new(valid_attrs)
    assert order.valid?
  end

  test "order_type enum accepts one_off and recurring" do
    order = Order.new(valid_attrs(order_type: :one_off))
    assert order.one_off?

    order.order_type = :recurring
    assert order.recurring?
  end

  test "frequency is optional for one_off orders" do
    order = Order.new(valid_attrs(order_type: :one_off, frequency: nil))
    assert order.valid?
  end

  test "frequency accepts weekly, monthly, quarterly" do
    order = Order.new(valid_attrs)

    order.frequency = :weekly
    assert order.weekly?

    order.frequency = :monthly
    assert order.monthly?

    order.frequency = :quarterly
    assert order.quarterly?
  end

  test "status defaults to pending" do
    order = Order.create!(valid_attrs)
    assert order.pending?
  end

  test "status lifecycle: pending -> generated -> dispatched -> printed -> shipped -> delivered" do
    order = Order.create!(valid_attrs)
    assert order.pending?

    order.generated!
    assert order.generated?

    order.dispatched!
    assert order.dispatched?

    order.printed!
    assert order.printed?

    order.shipped!
    assert order.shipped?

    order.delivered!
    assert order.delivered?
  end

  test "page_count must be a positive integer" do
    order = Order.new(valid_attrs(page_count: nil))
    assert_not order.valid?

    order.page_count = 0
    assert_not order.valid?

    order.page_count = -1
    assert_not order.valid?

    order.page_count = 2.5
    assert_not order.valid?

    order.page_count = 4
    assert order.valid?
  end

  test "delivery_address is required" do
    order = Order.new(valid_attrs(delivery_address: nil))
    assert_not order.valid?
    assert_includes order.errors[:delivery_address], "can't be blank"
  end

  test "newsletter_ids stores and retrieves an array of integers" do
    ids = [ 10, 20, 30 ]
    order = Order.create!(valid_attrs(newsletter_ids: ids))
    order.reload
    assert_equal ids, order.newsletter_ids
  end

  test "order belongs_to user" do
    order = Order.create!(valid_attrs)
    assert_equal @user, order.user
  end

  test "order belongs_to newspaper optionally" do
    order = Order.new(valid_attrs(newspaper_id: nil))
    assert order.valid?
  end

  test "stripe_payment_id is required" do
    order = Order.new(valid_attrs(stripe_payment_id: nil))
    assert_not order.valid?
    assert_includes order.errors[:stripe_payment_id], "can't be blank"
  end
end
