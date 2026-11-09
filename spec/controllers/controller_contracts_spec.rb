# frozen_string_literal: true

require "spec_helper"

RSpec.describe MockApplePiesController, type: :controller do
  let(:grandma) { create(:grandma, pies_count: 1) }
  let(:pie) { grandma.mock_apple_pies.first }
  let(:attributes) { {ingredients: "love"} }

  before do
    controller.current_grandma = grandma
  end

  def dispatch_mutation(action, format)
    case action
    when :create
      post :create,
        params: {mock_apple_pie: attributes},
        format: format
    when :update
      put :update,
        params: {id: pie.id, mock_apple_pie: attributes},
        format: format
    when :destroy
      delete :destroy, params: {id: pie.id}, format: format
    end
  end

  def with_aborted_callback(kind, message: nil)
    callback = proc do
      errors.add(:base, message) if message
      throw :abort
    end

    MockApplePie.set_callback(kind, :before, callback)

    begin
      yield
    ensure
      MockApplePie.skip_callback(kind, :before, callback)
    end
  end

  describe "security scoping" do
    before do
      controller.define_singleton_method(:scoped_resource) do
        collection.none
      end
    end

    it "excludes records from index" do
      get :index, format: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("mock_apple_pies" => [])
    end

    %i[show edit update destroy].each do |action|
      it "returns JSON 404 for scoped-out #{action}" do
        original = pie.attributes

        case action
        when :show, :edit
          get action, params: {id: pie.id}, format: :json
        else
          dispatch_mutation(action, :json)
        end

        expect(response).to have_http_status(:not_found)
        expect(pie.reload.attributes).to eq(original)
      end

      it "returns HTML not-found for scoped-out #{action}" do
        original = pie.attributes

        expect do
          case action
          when :show, :edit
            get action, params: {id: pie.id}
          else
            dispatch_mutation(action, :html)
          end
        end.to raise_error(ActionController::RoutingError)

        expect(pie.reload.attributes).to eq(original)
      end
    end

    it "preserves the scope for custom lookups" do
      controller.define_singleton_method(:find_in_collection) do |resources, value|
        resources.find_by(ingredients: value)
      end

      get :show, params: {id: pie.ingredients}, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it "supports custom lookups within the allowed scope" do
      controller.define_singleton_method(:scoped_resource) { collection }
      controller.define_singleton_method(:find_in_collection) do |resources, value|
        resources.find_by(ingredients: value)
      end

      get :show, params: {id: pie.ingredients}, format: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("mock_apple_pie", "id")).to eq(pie.id)
    end
  end

  describe "custom primary keys" do
    around do |example|
      original_primary_key = MockApplePie.primary_key
      pie
      MockApplePie.primary_key = "ingredients"

      begin
        example.run
      ensure
        MockApplePie.primary_key = original_primary_key
      end
    end

    it "finds a record using its configured primary key" do
      get :show, params: {id: pie.ingredients}, format: :json

      expect(response).to have_http_status(:ok)
      expect(
        response.parsed_body.dig("mock_apple_pie", "ingredients")
      ).to eq(pie.ingredients)
    end

    it "returns nil from the lookup for an unknown identifier" do
      resources = grandma.mock_apple_pies

      expect(controller.send(:find_in_collection, resources, "missing")).to be_nil
    end

    it "returns 404 for an unknown identifier" do
      get :show, params: {id: "missing"}, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it "preserves the security scope" do
      identifier = pie.ingredients

      controller.define_singleton_method(:scoped_resource) do
        collection.none
      end

      get :show, params: {id: identifier}, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "aborted persistence" do
    %i[create update destroy].each do |action|
      %i[html json].each do |format|
        it "rejects aborted #{action} as #{format} without changing records" do
          original = pie.attributes
          count = MockApplePie.count
          callback_kind = (action == :destroy) ? :destroy : :save

          with_aborted_callback(callback_kind) do
            dispatch_mutation(action, format)
          end

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash[:notice]).to be_nil
          expect(MockApplePie.count).to eq(count)
          expect(pie.reload.attributes).to eq(original)

          if format == :json
            errors = response.parsed_body.dig("mock_apple_pie", "errors")
            expect(errors.fetch("base")).not_to be_empty
          end
        end
      end
    end

    it "preserves callback-provided errors" do
      pie

      with_aborted_callback(:save, message: "Updates are locked") do
        dispatch_mutation(:update, :json)
      end

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("mock_apple_pie", "errors")).to eq(
        "base" => ["Updates are locked"]
      )
    end

    it "preserves validation errors without adding a generic error" do
      post :create,
        params: {mock_apple_pie: {ingredients: ""}},
        format: :json

      expect(response).to have_http_status(:unprocessable_entity)

      errors = response.parsed_body.dig("mock_apple_pie", "errors")
      expect(errors.fetch("ingredients")).not_to be_empty
      expect(errors).not_to have_key("base")
    end

    it "does not turn unexpected exceptions into validation failures" do
      allow(controller).to receive(:update_resource)
        .and_raise(RuntimeError, "database unavailable")

      expect do
        dispatch_mutation(:update, :json)
      end.to raise_error(RuntimeError, "database unavailable")
    end
  end

  describe "destroy operations" do
    it "completes deletion without reloading the collection" do
      id = pie.id
      resources = grandma.mock_apple_pies
      allow(controller).to receive(:collection).and_return(resources)
      allow(resources).to receive(:reload).and_raise("unexpected collection reload")

      dispatch_mutation(:destroy, :json)

      expect(response).to have_http_status(:no_content)
      expect(MockApplePie.exists?(id)).to be(false)
    end

    it "returns the resource after successful destruction" do
      resource = pie

      expect(controller.send(:destroy_resource, resource)).to equal(resource)
      expect(resource).to be_destroyed
    end

    it "returns the resource after aborted destruction" do
      resource = pie

      with_aborted_callback(:destroy) do
        expect(controller.send(:destroy_resource, resource)).to equal(resource)
      end

      expect(resource).not_to be_destroyed
      expect(MockApplePie.exists?(resource.id)).to be(true)
    end
  end

  describe "redirect hooks" do
    before do
      controller.define_singleton_method(:after_resource_created_path) do |_resource|
        {action: :index}
      end

      controller.define_singleton_method(:after_resource_updated_path) do |resource|
        {action: :edit, id: resource.id}
      end
    end

    it "uses the create destination" do
      dispatch_mutation(:create, :html)

      expect(response).to redirect_to(action: :index)
    end

    it "uses the update destination" do
      dispatch_mutation(:update, :html)

      expect(response).to redirect_to(action: :edit, id: pie.id)
    end

    it "keeps JSON creation's status and Location header" do
      dispatch_mutation(:create, :json)

      expect(response).to have_http_status(:created)

      id = response.parsed_body.dig("mock_apple_pie", "id")
      expect(URI.parse(response.location).path).to eq("/mock_apple_pies/#{id}")
    end
  end

  describe "serialization" do
    [true, false].each do |root|
      [:default, :custom].each do |serializer|
        context "#{serializer} serializer with root=#{root}" do
          before do
            controller.define_singleton_method(:include_root?) { root }

            if serializer == :custom
              controller.define_singleton_method(:serializable_resource) do |resource|
                resource.as_json(root: false, only: [:id, :ingredients])
              end
            end
          end

          it "returns member data rather than encoded JSON" do
            get :show, params: {id: pie.id}, format: :json

            body = response.parsed_body
            data = root ? body.fetch("mock_apple_pie") : body

            expect(response).to have_http_status(:ok)
            expect(data).to include(
              "id" => pie.id,
              "ingredients" => pie.ingredients
            )
            expect(data).not_to have_key("grandma_id") if serializer == :custom
          end

          it "returns collection data rather than encoded JSON" do
            get :index, format: :json

            body = response.parsed_body
            data = root ? body.fetch("mock_apple_pies") : body

            expect(response).to have_http_status(:ok)
            expect(data).to contain_exactly(
              a_hash_including("id" => pie.id)
            )
          end

          it "includes errors independently of the serializer" do
            post :create,
              params: {mock_apple_pie: {ingredients: ""}},
              format: :json

            body = response.parsed_body
            data = root ? body.fetch("mock_apple_pie") : body

            expect(response).to have_http_status(:unprocessable_entity)
            expect(data.fetch("errors").fetch("ingredients")).not_to be_empty
          end
        end
      end
    end

    %i[show index].each do |action|
      it "rejects encoded JSON from the #{action} serializer" do
        controller.define_singleton_method(:serializable_resource) do |resource|
          resource.to_json
        end

        expect do
          get action, params: {id: pie.id}, format: :json
        end.to raise_error(TypeError, /serializable_resource must return/)
      end
    end
  end
end
