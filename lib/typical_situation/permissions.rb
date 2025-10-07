# frozen_string_literal: true

module TypicalSituation
  module Permissions
    def authorized?(_action, _resource = nil)
      true
    end

    def respond_as_forbidden
      respond_to do |format|
        format.html { render plain: "Forbidden", status: :forbidden }
        format.json { head :forbidden }
      end
    end
  end
end
