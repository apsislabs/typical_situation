# frozen_string_literal: true

class MockApplePiesController < ApplicationController
  include TypicalSituation

  typical_situation :mock_apple_pie

  attr_accessor :current_grandma

  private

  # The collection of model instances.
  def collection
    current_grandma.mock_apple_pies
  end
end
