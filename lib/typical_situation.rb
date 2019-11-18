# frozen_string_literal: true

require 'typical_situation/railtie'
require 'typical_situation/identity'
require 'typical_situation/actions'
require 'typical_situation/operations'
require 'typical_situation/responses'

module TypicalSituation
  module Controller
    extend ActiveSupport::Concern

    class_methods do
      attr_reader :__typify_json_only
      attr_reader :__model_type

      def typify(model_name, json_only: false)
        @__typify_json_only = json_only
        @__model_type = model_name

        include Identity
        include Actions
        include Operations
        include Responses

        add_rescues(self)
      end

      def add_rescues(action_controller)
        action_controller.class_eval do
          rescue_from ActiveRecord::RecordNotFound, with: :respond_as_not_found
        end
      end
    end
  end
end
