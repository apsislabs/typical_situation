# frozen_string_literal: true

module TypicalSituation
  module Permissions
    def authorized?(_action, _resource = nil)
      true
    end
  end
end
