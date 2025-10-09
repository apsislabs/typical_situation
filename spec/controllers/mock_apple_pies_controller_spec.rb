# frozen_string_literal: true

require "spec_helper"

PIES_COUNT = 5

RSpec.describe MockApplePiesController, type: :controller do
  before(:each) do
    @grandma = create(:grandma, pies_count: PIES_COUNT)
    controller.current_grandma = @grandma
  end

  let(:pie) { @grandma.mock_apple_pies.first }

  describe "GET #index" do
    context "html" do
      it "renders the index template" do
        get :index

        expect(response).to have_http_status :ok
        expect(response).to render_template(:index)
        expect(assigns(:mock_apple_pies)).not_to be nil
        expect(assigns(:mock_apple_pies).size).to eq PIES_COUNT
      end
    end

    context "json" do
      it "renders index JSON" do
        get :index, format: :json

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status :ok
        expect(response_body).to be_a Hash
        expect(response_body["mock_apple_pies"]).to be_a Array
        expect(response_body["mock_apple_pies"].size).to eq PIES_COUNT

        response_body["mock_apple_pies"].each do |pie|
          expect(@grandma.id).to eq pie["grandma_id"]
          expect(pie["ingredients"]).not_to be nil
        end
      end
    end
  end

  describe "GET #show" do
    context "html" do
      it "renders the show template" do
        get :show, params: {id: pie.to_param}

        expect(response).to have_http_status :ok
        expect(response).to render_template(:show)

        expect(assigns(:mock_apple_pie)).not_to be nil
        expect(assigns(:mock_apple_pie)).to be_a MockApplePie
      end

      it "renders not_found" do
        expect { get :show, params: {id: 555} }.to raise_error(ActionController::RoutingError)
      end
    end

    context "json" do
      it "renders show JSON" do
        get :show, params: {id: pie.to_param}, format: :json

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status :ok
        expect(response_body).to be_a Hash
        expect(response_body["mock_apple_pie"]).to be_a Hash
        expect(response_body["mock_apple_pie"]["grandma_id"]).to eq @grandma.id
      end

      it "renders not_found" do
        get :show, params: {id: 555}, format: :json
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "GET #new" do
    it "renders the new template" do
      get :new

      expect(response).to have_http_status :ok
      expect(response).to render_template(:new)

      expect(assigns(:mock_apple_pie)).not_to be nil
      expect(assigns(:mock_apple_pie)).to be_a MockApplePie
    end
  end

  describe "POST #create" do
    let(:new_attrs) { {mock_apple_pie: {ingredients: "love", grandma_id: @grandma.id}} }
    let(:bad_attrs) { {mock_apple_pie: {ingredients: "", grandma_id: @grandma.id}} }

    context "html" do
      it "redirects to show" do
        post :create, params: new_attrs
        pie = MockApplePie.all.last
        expect(response).to have_http_status :redirect
        expect(response).to redirect_to(action: :show, id: pie.id)
      end

      it "sets success flash message" do
        post :create, params: new_attrs
        expect(flash[:notice]).to eq("Mock apple pie was successfully created")
      end

      it "renders 422 for invalid args" do
        post :create, params: bad_attrs
        expect(response).to have_http_status :unprocessable_entity
      end

      it "does not set flash message for invalid create" do
        post :create, params: bad_attrs
        expect(flash[:notice]).to be_nil
        expect(flash[:error]).to be_nil
      end
    end

    context "json" do
      it "creates successfully" do
        post :create, params: new_attrs.merge(format: :json)
        response_body = JSON.parse(response.body)

        expect(response).to have_http_status :created
        expect(response_body).to be_a Hash
        expect(response_body["mock_apple_pie"]).to be_a Hash
        expect(response_body["mock_apple_pie"]["grandma_id"]).to eq @grandma.id
        expect(response_body["mock_apple_pie"]["ingredients"]).to eq new_attrs[:mock_apple_pie][:ingredients]
      end

      it "renders 422 for invalid args" do
        post :create, params: bad_attrs.merge(format: :json)
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe "GET #edit" do
    it "renders the new template" do
      get :edit, params: {id: pie.to_param}

      expect(response).to have_http_status :ok
      expect(response).to render_template(:edit)

      expect(assigns(:mock_apple_pie)).not_to be nil
      expect(assigns(:mock_apple_pie)).to be_a MockApplePie
    end

    it "renders not_found" do
      expect { get :edit, params: {id: 555} }.to raise_error(ActionController::RoutingError)
    end
  end

  describe "PUT #update" do
    let(:update_attrs) { {mock_apple_pie: {ingredients: "lots of love"}} }
    let(:bad_attrs) { {mock_apple_pie: {ingredients: ""}} }

    context "html" do
      it "redirects to show" do
        put :update, params: update_attrs.merge(id: pie.to_param)
        expect(response).to have_http_status :redirect
        expect(response).to redirect_to(action: :show, id: pie.to_param)
      end

      it "sets success flash message" do
        put :update, params: update_attrs.merge(id: pie.to_param)
        expect(flash[:notice]).to eq("Mock apple pie was successfully updated")
      end

      it "renders not_found" do
        expect { put :update, params: update_attrs.merge(id: 555) }.to raise_error(ActionController::RoutingError)
      end

      it "renders unprocessable_entity" do
        put :update, params: bad_attrs.merge(id: pie.to_param)
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context "json" do
      it "updates successfully" do
        put :update, params: update_attrs.merge(id: pie.to_param, format: :json)
        response_body = JSON.parse(response.body)

        expect(response).to have_http_status :ok
        expect(response_body).to be_a Hash
        expect(response_body["mock_apple_pie"]).to be_a Hash
        expect(response_body["mock_apple_pie"]["ingredients"]).to eq update_attrs[:mock_apple_pie][:ingredients]
      end

      it "renders not_found" do
        put :update, params: update_attrs.merge(id: 555, format: :json)
        expect(response).to have_http_status :not_found
      end

      it "renders unprocessable_entity" do
        put :update, params: bad_attrs.merge(id: pie.to_param, format: :json)
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe "DELETE #destroy" do
    context "html" do
      it "redirects to index" do
        delete :destroy, params: {id: pie.to_param}
        expect(response).to have_http_status :redirect
        expect(response).to redirect_to(action: :index)
      end

      it "sets success flash message" do
        delete :destroy, params: {id: pie.to_param}
        expect(flash[:notice]).to eq("Mock apple pie was successfully deleted")
      end

      it "renders not_found" do
        expect { delete :destroy, params: {id: 555} }.to raise_error(ActionController::RoutingError)
      end

      it "renders unprocessable_entity" do
        pie.update_attribute(:ingredients, "real apples")

        delete :destroy, params: {id: pie.to_param}
        expect(response).to have_http_status :unprocessable_entity
      end

      it "sets error flash message for failed deletion" do
        pie.update_attribute(:ingredients, "real apples")

        delete :destroy, params: {id: pie.to_param}
        expect(flash[:error]).to include("can't be deleted because it contains real apple")
      end
    end

    context "json" do
      it "deletes successfully" do
        delete :destroy, params: {id: pie.to_param}, format: :json
        expect(response).to have_http_status :no_content
        expect(response.body).to be_empty
      end

      it "renders not_found" do
        delete :destroy, params: {id: 555}, format: :json
        expect(response).to have_http_status :not_found
      end

      it "renders unprocessable_entity" do
        pie.update_attribute(:ingredients, "real apples")

        delete :destroy, params: {id: pie.to_param}, format: :json
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe "customization hooks" do
    describe "default behavior" do
      it "scoped_resource returns collection" do
        expect(controller.scoped_resource).to eq(@grandma.mock_apple_pies)
      end

      it "find_resource calls find_in_collection" do
        result = controller.find_resource(pie.id)
        expect(result).to eq(pie)
      end

      it "default_sorting_attribute returns nil" do
        expect(controller.default_sorting_attribute).to be_nil
      end

      it "default_sorting_direction returns :asc" do
        expect(controller.default_sorting_direction).to eq(:asc)
      end

      it "paginate_resources returns unchanged resources" do
        resources = @grandma.mock_apple_pies
        expect(controller.paginate_resources(resources)).to eq(resources)
      end

      it "after_resource_created_path returns show path" do
        path = controller.after_resource_created_path(pie)
        expect(path).to eq({action: :show, id: pie.id})
      end

      it "after_resource_updated_path returns show path" do
        path = controller.after_resource_updated_path(pie)
        expect(path).to eq({action: :show, id: pie.id})
      end

      it "after_resource_destroyed_path returns index path" do
        path = controller.after_resource_destroyed_path(pie)
        expect(path).to eq({action: :index})
      end
    end

    describe "pagination_params" do
      it "permits page and per_page params" do
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(page: "2", per_page: "10", other: "ignored")
        )

        permitted = controller.pagination_params
        expect(permitted[:page]).to eq("2")
        expect(permitted[:per_page]).to eq("10")
        expect(permitted[:other]).to be_nil
      end
    end

    describe "strong params" do
      let(:full_params) { ActionController::Parameters.new(mock_apple_pie: {ingredients: "love", grandma_id: 1, secret_field: "hidden"}) }

      before do
        allow(controller).to receive(:params).and_return(full_params)
      end

      describe "#permitted_create_params" do
        it "returns nil by default" do
          expect(controller.permitted_create_params).to be_nil
        end
      end

      describe "#permitted_update_params" do
        it "returns nil by default" do
          expect(controller.permitted_update_params).to be_nil
        end
      end

      describe "#create_params" do
        it "permits all params when permitted_create_params is nil" do
          allow(controller).to receive(:permitted_create_params).and_return(nil)
          result = controller.create_params
          expect(result[:ingredients]).to eq("love")
          expect(result[:grandma_id]).to eq(1)
          expect(result[:secret_field]).to eq("hidden")
        end

        it "permits all params when permitted_create_params is empty" do
          allow(controller).to receive(:permitted_create_params).and_return([])
          result = controller.create_params
          expect(result[:ingredients]).to eq("love")
          expect(result[:grandma_id]).to eq(1)
          expect(result[:secret_field]).to eq("hidden")
        end

        it "filters params when permitted_create_params is specified" do
          allow(controller).to receive(:permitted_create_params).and_return([:ingredients])
          result = controller.create_params
          expect(result[:ingredients]).to eq("love")
          expect(result[:grandma_id]).to be_nil
          expect(result[:secret_field]).to be_nil
        end
      end

      describe "#update_params" do
        it "permits all params when permitted_update_params is nil" do
          allow(controller).to receive(:permitted_update_params).and_return(nil)
          result = controller.update_params
          expect(result[:ingredients]).to eq("love")
          expect(result[:grandma_id]).to eq(1)
          expect(result[:secret_field]).to eq("hidden")
        end

        it "permits all params when permitted_update_params is empty" do
          allow(controller).to receive(:permitted_update_params).and_return([])
          result = controller.update_params
          expect(result[:ingredients]).to eq("love")
          expect(result[:grandma_id]).to eq(1)
          expect(result[:secret_field]).to eq("hidden")
        end

        it "filters params when permitted_update_params is specified" do
          allow(controller).to receive(:permitted_update_params).and_return([:ingredients])
          result = controller.update_params
          expect(result[:ingredients]).to eq("love")
          expect(result[:grandma_id]).to be_nil
          expect(result[:secret_field]).to be_nil
        end
      end
    end
  end
end
