class FurniturePlacement::Serializer < ApplicationSerializer
  # @return [FurniturePlacement]
  alias furniture_placement resource

  def to_json(*_args)
    super.merge(
      furniture_placement: {
        id: furniture_placement.id,
      }
    )
  end
end
