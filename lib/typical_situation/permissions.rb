# frozen_string_literal: true

module TypicalSituation
  module Permissions
    protected

    def authorized?(_action, _resource = nil)
      true
    end
  end
end
