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
end
