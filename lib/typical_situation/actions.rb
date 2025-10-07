# frozen_string_literal: true

module TypicalSituation
  # Standard REST/CRUD actions.
  module Actions
    def index
      raise TypicalSituation::ActionForbidden unless authorized?(:index)

      get_resources
      respond_with_resources
    end

    def show
      get_resource
      raise TypicalSituation::ActionForbidden unless authorized?(:show, @resource)

      respond_with_resource
    end

    def edit
      get_resource
      raise TypicalSituation::ActionForbidden unless authorized?(:edit, @resource)

      respond_with_resource
    end

    def new
      raise TypicalSituation::ActionForbidden unless authorized?(:new)

      new_resource
      respond_with_resource
    end

    def update
      get_resource
      raise TypicalSituation::ActionForbidden unless authorized?(:update, @resource)

      update_resource(@resource, update_params)
      respond_as_changed
    end

    def destroy
      get_resource
      raise TypicalSituation::ActionForbidden unless authorized?(:destroy, @resource)

      destroy_resource(@resource)
      respond_as_gone
    end

    def create
      raise TypicalSituation::ActionForbidden unless authorized?(:create)

      @resource = create_resource(create_params)
      respond_as_created
    end
  end
end
