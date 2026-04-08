# frozen_string_literal: true

class Bicycle < Vehicle
  has_tags :terrain_types, tag_class_name: "VehicleTag", tagging_class_name: "Vehicle::Tagging"
end
