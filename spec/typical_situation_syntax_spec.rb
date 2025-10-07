# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'TypicalSituation syntax sugar' do
  describe 'typical_situation class method' do
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

    it 'defines model_type method' do
      expect(controller.model_type).to eq(:test_model)
    end

    it 'works with all typical situation functionality' do
      expect(controller.model_class).to eq(TestModel)
    end

    it 'works with plural_model_type' do
      expect(controller.plural_model_type).to eq(:test_models)
    end

    it 'works with model_params' do
      # Mock params
      allow(controller).to receive(:params) do
        ActionController::Parameters.new(
          test_model: { name: 'Test' }
        )
      end

      expect(controller.model_params).to be_a(ActionController::Parameters)
      expect(controller.model_params[:name]).to eq('Test')
    end
  end

  describe 'backward compatibility' do
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

    it 'produces identical behavior between old and new syntax' do
      old_controller = old_syntax_controller_class.new
      new_controller = new_syntax_controller_class.new

      expect(old_controller.model_type).to eq(new_controller.model_type)
      expect(old_controller.plural_model_type).to eq(new_controller.plural_model_type)
    end
  end

  describe 'class method availability' do
    it 'adds typical_situation class method when module is included' do
      controller_class = Class.new(ApplicationController) do
        include TypicalSituation
      end

      expect(controller_class).to respond_to(:typical_situation)
    end

    it 'does not add class method to classes that do not include TypicalSituation' do
      controller_class = Class.new(ApplicationController)

      expect(controller_class).not_to respond_to(:typical_situation)
    end
  end
end