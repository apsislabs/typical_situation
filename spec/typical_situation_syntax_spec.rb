# frozen_string_literal: true

require "spec_helper"

RSpec.describe "TypicalSituation syntax sugar" do
  describe "typical_situation class method" do
    let(:controller_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        typical_situation :test_model

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end
    end

    let(:controller) { controller_class.new }
    let(:grandma) { create(:grandma) }

    before do
      controller.current_grandma = grandma
    end

    it "defines model_type method" do
      expect(controller.model_type).to eq(:test_model)
    end

    it "works with all typical situation functionality" do
      expect(controller.model_class).to eq(TestModel)
    end

    it "works with plural_model_type" do
      expect(controller.plural_model_type).to eq(:test_models)
    end

    it "works with model_params" do
      # Mock params
      allow(controller).to receive(:params) do
        ActionController::Parameters.new(
          test_model: {name: "Test"}
        )
      end

      expect(controller.model_params).to be_a(ActionController::Parameters)
      expect(controller.model_params[:name]).to eq("Test")
    end
  end

  describe "with only parameter" do
    let(:limited_controller_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        typical_situation :test_model, only: %i[index show]

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end
    end

    let(:limited_controller) { limited_controller_class.new }
    let(:grandma) { create(:grandma) }

    before do
      limited_controller.current_grandma = grandma
    end

    it "only defines specified actions" do
      expect(limited_controller).to respond_to(:index)
      expect(limited_controller).to respond_to(:show)
      expect(limited_controller).not_to respond_to(:create)
      expect(limited_controller).not_to respond_to(:update)
      expect(limited_controller).not_to respond_to(:destroy)
    end

    it "still works with model_type functionality" do
      expect(limited_controller.model_type).to eq(:test_model)
    end
  end

  describe "typical_rest class method" do
    let(:rest_controller_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        typical_rest :test_model

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end
    end

    let(:rest_controller) { rest_controller_class.new }
    let(:grandma) { create(:grandma) }

    before do
      rest_controller.current_grandma = grandma
    end

    it "defines model_type method" do
      expect(rest_controller.model_type).to eq(:test_model)
    end

    it "includes all REST actions" do
      expect(rest_controller).to respond_to(:index)
      expect(rest_controller).to respond_to(:show)
      expect(rest_controller).to respond_to(:new)
      expect(rest_controller).to respond_to(:create)
      expect(rest_controller).to respond_to(:edit)
      expect(rest_controller).to respond_to(:update)
      expect(rest_controller).to respond_to(:destroy)
    end

    it "is equivalent to typical_situation without only parameter" do
      equivalent_class = Class.new(ApplicationController) do
        include TypicalSituation

        typical_situation :test_model

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end

      equivalent_controller = equivalent_class.new
      equivalent_controller.current_grandma = grandma

      expect(rest_controller.model_type).to eq(equivalent_controller.model_type)

      %i[index show new create edit update destroy].each do |action|
        expect(rest_controller.respond_to?(action)).to eq(equivalent_controller.respond_to?(action))
      end
    end
  end

  describe "typical_crud class method" do
    let(:crud_controller_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        typical_crud :test_model

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end
    end

    let(:crud_controller) { crud_controller_class.new }
    let(:grandma) { create(:grandma) }

    before do
      crud_controller.current_grandma = grandma
    end

    it "defines model_type method" do
      expect(crud_controller.model_type).to eq(:test_model)
    end

    it "includes only CRUD actions" do
      expect(crud_controller).to respond_to(:create)
      expect(crud_controller).to respond_to(:show)
      expect(crud_controller).to respond_to(:update)
      expect(crud_controller).to respond_to(:destroy)
    end

    it "does not include non-CRUD actions" do
      expect(crud_controller).not_to respond_to(:index)
      expect(crud_controller).not_to respond_to(:new)
      expect(crud_controller).not_to respond_to(:edit)
    end

    it "is equivalent to typical_situation with CRUD only actions" do
      equivalent_class = Class.new(ApplicationController) do
        include TypicalSituation

        typical_situation :test_model, only: %i[create show update destroy]

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end

      equivalent_controller = equivalent_class.new
      equivalent_controller.current_grandma = grandma

      expect(crud_controller.model_type).to eq(equivalent_controller.model_type)

      %i[index show new create edit update destroy].each do |action|
        expect(crud_controller.respond_to?(action)).to eq(equivalent_controller.respond_to?(action))
      end
    end
  end

  describe "helper method differences" do
    let(:grandma) { create(:grandma) }

    let(:rest_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        typical_rest :test_model
        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end
    end

    let(:crud_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        typical_crud :test_model
        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end
    end

    let(:rest_controller) { rest_class.new.tap { |c| c.current_grandma = grandma } }
    let(:crud_controller) { crud_class.new.tap { |c| c.current_grandma = grandma } }

    it "typical_rest includes more actions than typical_crud" do
      rest_actions = %i[index show new create edit update destroy].select do |action|
        rest_controller.respond_to?(action)
      end

      crud_actions = %i[index show new create edit update destroy].select do |action|
        crud_controller.respond_to?(action)
      end

      expect(rest_actions.count).to be > crud_actions.count
    end

    it "typical_crud excludes form-related actions" do
      expect(crud_controller).not_to respond_to(:new)
      expect(crud_controller).not_to respond_to(:edit)
      expect(crud_controller).not_to respond_to(:index)
    end

    it "both helpers work with model_type functionality" do
      expect(rest_controller.model_type).to eq(:test_model)
      expect(crud_controller.model_type).to eq(:test_model)
      expect(rest_controller.model_class).to eq(TestModel)
      expect(crud_controller.model_class).to eq(TestModel)
    end
  end

  describe "backward compatibility" do
    let(:old_syntax_controller_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        def model_type
          :legacy_model
        end

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end
    end

    let(:new_syntax_controller_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        typical_situation :legacy_model

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end

        def find_in_collection(id)
          collection.find_by_id(id)
        end
      end
    end

    it "produces identical behavior between old and new syntax" do
      old_controller = old_syntax_controller_class.new
      new_controller = new_syntax_controller_class.new

      expect(old_controller.model_type).to eq(new_controller.model_type)
      expect(old_controller.plural_model_type).to eq(new_controller.plural_model_type)
    end
  end

  describe "class method availability" do
    it "adds typical_situation class method when module is included" do
      controller_class = Class.new(ApplicationController) do
        include TypicalSituation
      end

      expect(controller_class).to respond_to(:typical_situation)
    end

    it "adds typical_rest class method when module is included" do
      controller_class = Class.new(ApplicationController) do
        include TypicalSituation
      end

      expect(controller_class).to respond_to(:typical_rest)
    end

    it "adds typical_crud class method when module is included" do
      controller_class = Class.new(ApplicationController) do
        include TypicalSituation
      end

      expect(controller_class).to respond_to(:typical_crud)
    end

    it "does not add class methods to classes that do not include TypicalSituation" do
      controller_class = Class.new(ApplicationController)

      expect(controller_class).not_to respond_to(:typical_situation)
      expect(controller_class).not_to respond_to(:typical_rest)
      expect(controller_class).not_to respond_to(:typical_crud)
    end
  end
end
