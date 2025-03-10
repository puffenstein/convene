# frozen_string_literal: true

# Allows a Space to receive Payments
# @see features/furniture/payment-form.feature
class PaymentForm
  include Placeable

  def self.deprecated_append_routes(router)
    router.scope module: 'payment_form' do
      router.resource :payment_form, only: [:show] do
        router.resources :payments, only: %i[create index]
      end
    end
  end

  # @return [ActiveRecord::Relation<Payment>]
  def payments
    Payment.where(location: placement)
  end

  # @deprecated
  def in_room_template
    "#{self.class.furniture_kind}/in_room"
  end

  def link_token_for(person)
    utilities.plaid.create_link_token(person: person, space: placement.space)
  end
end
