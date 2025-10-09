# frozen_string_literal: true

module TypicalSituation
  module FlashMessages
    private

    def set_success_flash(action)
      flash[:notice] = translate_with_resource("#{action}.success")
    end

    def set_error_flash
      return unless @resource&.errors&.any?

      flash[:error] = @resource.errors.full_messages.join(", ")
    end

    def translate_with_resource(key)
      I18n.t(
        "typical_situation.flash.#{key}",
        resource: model_type.to_s.humanize
      )
    end
  end
end
