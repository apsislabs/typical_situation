# frozen_string_literal: true

class TestModel < ActiveRecord::Base
  belongs_to :grandma

  validates :name, presence: true
end