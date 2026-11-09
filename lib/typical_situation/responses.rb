# frozen_string_literal: true

module TypicalSituation
  # Rails MIME responses.
  module Responses
    protected

    # Return the collection as HTML or JSON
    #
    def respond_with_resources
      respond_to do |format|
        yield(format) if block_given?

        format.html do
          set_collection_instance
          render
        end
        format.json do
          render json: serialize_resources(@resources)
        end
      end
    end

    # Return the resource as HTML or JSON
    #
    # A provided block is passed the #respond_to format to further define responses.
    #
    def respond_with_resource
      respond_to do |format|
        yield(format) if block_given?

        format.html do
          set_single_instance
          render
        end
        format.json do
          render json: serialize_resource(@resource)
        end
      end
    end

    def respond_as_changed(success:)
      return respond_as_failure(:update) unless success

      respond_to do |format|
        yield(format) if block_given?

        format.html do
          set_success_flash(:update)
          set_single_instance
          changed_so_redirect || render
        end

        format.json do
          render json: serialize_resource(@resource)
        end
      end
    end

    def respond_as_created(success:)
      return respond_as_failure(:create) unless success

      respond_to do |format|
        yield(format) if block_given?

        format.html do
          set_success_flash(:create)
          set_single_instance
          created_so_redirect || render
        end

        format.json do
          render json: serialize_resource(@resource),
            location: location_url,
            status: :created
        end
      end
    end

    def respond_as_error
      respond_to do |format|
        yield(format) if block_given?

        format.html do
          set_single_instance
          render action: (@resource.new_record? ? :new : :edit),
            status: :unprocessable_entity
        end
        format.json do
          render json: serialize_resource(@resource, errors: true),
            status: :unprocessable_entity
        end
      end
    end

    def respond_as_gone(success:)
      return respond_as_failure(:destroy) unless success

      respond_to do |format|
        yield(format) if block_given?

        format.html do
          set_single_instance
          gone_so_redirect || render
        end

        format.json do
          head :no_content
        end
      end
    end

    def respond_as_not_found
      respond_to do |format|
        yield(format) if block_given?

        format.html do
          raise ActionController::RoutingError, "Not Found"
        end
        format.json do
          head :not_found
        end
      end
    end

    def respond_as_forbidden
      respond_to do |format|
        format.html { render plain: "Forbidden", status: :forbidden }
        format.json { head :forbidden }
      end
    end

    def after_resource_created_path(resource)
      {action: :show, id: resource.id}
    end

    def after_resource_updated_path(resource)
      {action: :show, id: resource.id}
    end

    def after_resource_destroyed_path(_resource)
      {action: :index}
    end

    def created_so_redirect
      redirect_to after_resource_created_path(@resource)
      true
    end

    # HTML response when @resource saved or updated.
    def changed_so_redirect
      redirect_to after_resource_updated_path(@resource)
      true
    end

    # HTML response when @resource deleted.
    def gone_so_redirect
      set_success_flash(:destroy)
      redirect_to after_resource_destroyed_path(@resource)
      true
    end

    private

    def respond_as_failure(action)
      if @resource.errors.empty?
        @resource.errors.add(
          :base,
          I18n.t("typical_situation.errors.operation_failed")
        )
      end

      set_error_flash if action == :destroy && request.format.html?
      respond_as_error
    end
  end
end
