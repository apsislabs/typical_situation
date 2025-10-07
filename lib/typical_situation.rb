# frozen_string_literal: true

require "typical_situation/identity"
require "typical_situation/permissions"
require "typical_situation/actions"
require "typical_situation/operations"
require "typical_situation/responses"

module TypicalSituation
  class Error < StandardError; end
  class ActionForbidden < Error; end

  include Identity
  include Permissions
  include Operations
  include Responses

  def self.included(base)
    add_rescues(base)
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
      define_method :model_type do
        model_type_symbol
      end

      if only
        only.each do |action|
          if TypicalSituation::Actions.method_defined?(action)
            define_method(action, TypicalSituation::Actions.instance_method(action))
          end
        end
      else
        include TypicalSituation::Actions
      end
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
