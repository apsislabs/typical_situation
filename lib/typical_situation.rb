# frozen_string_literal: true

require "typical_situation/engine"
require "typical_situation/identity"
require "typical_situation/permissions"
require "typical_situation/flash_messages"
require "typical_situation/actions"
require "typical_situation/operations"
require "typical_situation/responses"
require "typical_situation/serialization"

module TypicalSituation
  class Error < StandardError; end
  class ActionForbidden < Error; end

  ACTION_NAMES = Actions.public_instance_methods(false).map(&:to_s).freeze

  include Identity
  include Permissions
  include FlashMessages
  include Operations
  include Responses
  include Serialization

  def self.included(base)
    add_rescues(base)

    base.class_attribute :typical_action_names,
      instance_accessor: false,
      default: ACTION_NAMES

    base.extend(ClassMethods)
  end

  module ClassMethods
    # Syntactic sugar for defining model_type
    #
    # Example:
    #   class PostsController < ApplicationController
    #     include TypicalSituation
    #     typical_situation :post
    #   end
    #
    # This is equivalent to:
    #   def model_type
    #     :post
    #   end
    def typical_situation(model_type_symbol, only: nil)
      actions = only.nil? ? ACTION_NAMES : Array(only).map(&:to_s)
      unknown = actions - ACTION_NAMES

      if unknown.any?
        raise ArgumentError, "Unknown actions: #{unknown.join(", ")}"
      end

      self.typical_action_names = actions.freeze

      define_method(:model_type) { model_type_symbol }
      protected :model_type

      include TypicalSituation::Actions
    end

    def action_methods
      super - (ACTION_NAMES - typical_action_names)
    end

    def typical_rest(model_type_symbol)
      typical_situation(model_type_symbol, only: nil)
    end

    def typical_crud(model_type_symbol)
      typical_situation(model_type_symbol, only: %i[create show update destroy])
    end
  end

  def self.add_rescues(action_controller)
    action_controller.class_eval do
      rescue_from ActiveRecord::RecordNotFound, with: :respond_as_not_found
      rescue_from TypicalSituation::ActionForbidden, with: :respond_as_forbidden
    end
  end
end
