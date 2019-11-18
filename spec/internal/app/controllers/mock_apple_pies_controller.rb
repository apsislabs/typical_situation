# frozen_string_literal: true

class MockApplePiesController < ApplicationController
  typify :mock_apple_pie

  attr_accessor :current_grandma

  # The collection of model instances.
  def collection
    current_grandma.mock_apple_pies
  end

  # Find a model instance by ID.
  def find_in_collection(id)
    collection.find_by_id(id)
  end
end
