# frozen_string_literal: true

class Motorcycle < Vehicle
  has_tags :engine_types, tag_class_name: "VehicleTag", tagging_class_name: "Vehicle::Tagging"
end
