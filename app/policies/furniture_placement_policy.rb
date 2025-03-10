# frozen_string_literal: true

class FurniturePlacementPolicy < ApplicationPolicy
  alias furniture_placement object
  delegate :space, to: :furniture_placement

  class Scope < ApplicationScope
    def resolve
      room_policy_scope = RoomPolicy::Scope.new(person, Room.all)
      scope.joins(:room).where(room: room_policy_scope.resolve)
    end
  end

  def show?
    true
  end

  def update?
    person&.member_of?(furniture_placement.space)
  end

  alias edit? update?
  alias new? update?
  alias create? update?
  alias destroy? update?

  def permitted_attributes(_params)
    [:furniture_kind, :slot, furniture_attributes: furniture_params]
  end

  def furniture_params
    Furniture::REGISTRY.each_value.reduce([]) do |m, v|
      m.concat(v.new.attribute_names)
    end
  end
end
