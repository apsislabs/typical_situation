# frozen_string_literal: true

require "typical_situation/identity"
require "typical_situation/actions"
require "typical_situation/operations"
require "typical_situation/responses"

module TypicalSituation
  include Identity
  include Actions
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
    def typical_situation(model_type_symbol)
      define_method :model_type do
        model_type_symbol
      end
    end
  end

  def self.add_rescues(action_controller)
    action_controller.class_eval do
      rescue_from ActiveRecord::RecordNotFound, with: :respond_as_not_found
    end
  end
end
