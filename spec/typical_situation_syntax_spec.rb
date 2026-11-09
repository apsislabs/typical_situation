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
      end
    end

    let(:controller) { controller_class.new }
    let(:grandma) { create(:grandma) }

    before do
      controller.current_grandma = grandma
    end

    it "defines model_type method" do
      expect(controller.send(:model_type)).to eq(:test_model)
    end

    it "works with all typical situation functionality" do
      expect(controller.send(:model_class)).to eq(TestModel)
    end

    it "works with plural_model_type" do
      expect(controller.send(:plural_model_type)).to eq(:test_models)
    end

    it "works with model_params" do
      # Mock params
      allow(controller).to receive(:params) do
        ActionController::Parameters.new(
          test_model: {name: "Test"}
        )
      end

      expect(controller.send(:model_params)).to be_a(ActionController::Parameters)
      expect(controller.send(:model_params)[:name]).to eq("Test")
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
      end
    end

    let(:limited_controller) { limited_controller_class.new }
    let(:grandma) { create(:grandma) }

    before do
      limited_controller.current_grandma = grandma
    end

    it "only exposes specified HTTP actions" do
      expect(limited_controller_class.action_methods & TypicalSituation::ACTION_NAMES)
        .to contain_exactly("index", "show")
    end

    it "still works with model_type functionality" do
      expect(limited_controller.send(:model_type)).to eq(:test_model)
    end
  end

  describe "action configuration" do
    let(:parent_class) do
      Class.new(ApplicationController) do
        include TypicalSituation

        typical_rest :test_model
      end
    end

    it "restricts inherited HTTP actions without changing the parent or siblings" do
      parent_actions = parent_class.action_methods.dup
      sibling = Class.new(parent_class)
      child = Class.new(parent_class) do
        typical_situation :test_model, only: [:show]
      end

      expect(child.action_methods).to contain_exactly("show")
      expect(parent_class.action_methods).to eq(parent_actions)
      expect(sibling.action_methods).to eq(parent_actions)
    end

    it "rejects dispatch to an excluded inherited action" do
      stub_const("TestModelsController", parent_class)

      child = Class.new(parent_class) do
        typical_situation :test_model, only: [:show]
      end

      stub_const("LimitedTestModelsController", child)

      expect { child.new.process(:destroy) }
        .to raise_error(AbstractController::ActionNotFound)
    end

    [nil, [:show]].each do |only|
      [:before, :after].each do |order|
        it "preserves an explicit action defined #{order} configuration with only=#{only.inspect}" do
          klass = Class.new(ApplicationController) do
            include TypicalSituation
          end
          custom_show = proc { :custom }

          klass.define_method(:show, custom_show) if order == :before
          klass.typical_situation :test_model, only: only
          klass.define_method(:show, custom_show) if order == :after

          expect(klass.new.show).to eq(:custom)
          expect(klass.action_methods).to include("show")
        end
      end
    end

    it "leaves custom nonstandard actions available" do
      child = Class.new(parent_class) do
        def preview
          :preview
        end

        typical_situation :test_model, only: [:show]
      end

      expect(child.action_methods).to contain_exactly("show", "preview")
    end

    it "accepts string action names" do
      parent_class.typical_situation :test_model, only: ["show"]

      expect(parent_class.action_methods).to contain_exactly("show")
    end

    it "exposes no standard HTTP actions for an empty selection" do
      parent_class.typical_situation :test_model, only: []

      expect(parent_class.action_methods).to be_empty
    end

    it "rejects unknown actions without changing existing configuration" do
      actions = parent_class.action_methods.dup

      expect do
        parent_class.typical_situation :other_model, only: [:show, :typo]
      end.to raise_error(ArgumentError, "Unknown actions: typo")

      expect(parent_class.action_methods).to eq(actions)
      expect(parent_class.new.send(:model_type)).to eq(:test_model)
    end

    it "updates the exposed actions after Rails has cached them" do
      parent_class.action_methods
      parent_class.typical_situation :test_model, only: [:show]
      expect(parent_class.action_methods).to contain_exactly("show")

      parent_class.typical_rest :test_model
      expect(parent_class.action_methods).to include("create", "update", "destroy")
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
      end
    end

    let(:rest_controller) { rest_controller_class.new }
    let(:grandma) { create(:grandma) }

    before do
      rest_controller.current_grandma = grandma
    end

    it "defines model_type method" do
      expect(rest_controller.send(:model_type)).to eq(:test_model)
    end

    it "exposes all REST actions" do
      expect(rest_controller_class.action_methods & TypicalSituation::ACTION_NAMES)
        .to contain_exactly("index", "show", "new", "create", "edit", "update", "destroy")
    end

    it "is equivalent to typical_situation without only parameter" do
      equivalent_class = Class.new(ApplicationController) do
        include TypicalSituation

        typical_situation :test_model

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end
      end

      equivalent_controller = equivalent_class.new
      equivalent_controller.current_grandma = grandma

      expect(rest_controller.send(:model_type)).to eq(equivalent_controller.send(:model_type))

      expect(rest_controller_class.action_methods).to eq(equivalent_class.action_methods)
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
      end
    end

    let(:crud_controller) { crud_controller_class.new }
    let(:grandma) { create(:grandma) }

    before do
      crud_controller.current_grandma = grandma
    end

    it "defines model_type method" do
      expect(crud_controller.send(:model_type)).to eq(:test_model)
    end

    it "exposes only CRUD actions" do
      expect(crud_controller_class.action_methods & TypicalSituation::ACTION_NAMES)
        .to contain_exactly("create", "show", "update", "destroy")
    end

    it "is equivalent to typical_situation with CRUD only actions" do
      equivalent_class = Class.new(ApplicationController) do
        include TypicalSituation

        typical_situation :test_model, only: %i[create show update destroy]

        attr_accessor :current_grandma

        def collection
          current_grandma.mock_apple_pies
        end
      end

      equivalent_controller = equivalent_class.new
      equivalent_controller.current_grandma = grandma

      expect(crud_controller.send(:model_type)).to eq(equivalent_controller.send(:model_type))

      expect(crud_controller_class.action_methods).to eq(equivalent_class.action_methods)
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
      end
    end

    let(:rest_controller) { rest_class.new.tap { |c| c.current_grandma = grandma } }
    let(:crud_controller) { crud_class.new.tap { |c| c.current_grandma = grandma } }

    it "typical_rest includes more actions than typical_crud" do
      expect(rest_class.action_methods.count).to be > crud_class.action_methods.count
    end

    it "typical_crud excludes form-related actions" do
      expect(crud_class.action_methods).not_to include("new", "edit", "index")
    end

    it "both helpers work with model_type functionality" do
      expect(rest_controller.send(:model_type)).to eq(:test_model)
      expect(crud_controller.send(:model_type)).to eq(:test_model)
      expect(rest_controller.send(:model_class)).to eq(TestModel)
      expect(crud_controller.send(:model_class)).to eq(TestModel)
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
      end
    end

    it "produces identical behavior between old and new syntax" do
      old_controller = old_syntax_controller_class.new
      new_controller = new_syntax_controller_class.new

      expect(old_controller.send(:model_type)).to eq(new_controller.send(:model_type))
      expect(old_controller.send(:plural_model_type)).to eq(new_controller.send(:plural_model_type))
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
