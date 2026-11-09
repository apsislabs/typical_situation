# frozen_string_literal: true

module TypicalSituation
  module Serialization
    protected

    def serialize_resource(resource, errors: false)
      data = serialization_data(resource, Hash)
      data = data.merge("errors" => resource.errors.as_json) if errors

      include_root? ? {model_type => data} : data
    end

    def serialize_resources(resources)
      data = serialization_data(resources, Array)

      include_root? ? {plural_model_type => data} : data
    end

    def serializable_resource(resource)
      resource.as_json(root: false)
    end

    private

    def serialization_data(resource, expected_type)
      data = serializable_resource(resource)

      unless data.is_a?(expected_type)
        raise TypeError,
          "serializable_resource must return #{expected_type}, got #{data.class}"
      end

      data
    end
  end
end
