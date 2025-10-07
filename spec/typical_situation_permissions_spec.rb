# frozen_string_literal: true

require "spec_helper"

PIES_COUNT = 5

RSpec.describe MockApplePiesController, type: :controller do
  before(:each) do
    @grandma = create(:grandma, pies_count: PIES_COUNT)
    controller.current_grandma = @grandma
  end

  let(:pie) { @grandma.mock_apple_pies.first }

  describe "authorization" do
    describe "default behavior" do
      it "authorized? returns true by default" do
        expect(controller.authorized?(:show, pie)).to be true
        expect(controller.authorized?(:destroy, pie)).to be true
      end
    end

    describe "custom authorization" do
      let(:controller_class) do
        Class.new(MockApplePiesController) do
          def authorized?(action, resource = nil)
            case action
            when :destroy
              resource&.ingredients != "forbidden_ingredient"
            when :show
              resource&.ingredients != "secret_ingredient"
            else
              true
            end
          end
        end
      end

      let(:custom_controller) { controller_class.new }

      before do
        custom_controller.current_grandma = @grandma
      end

      it "allows destroy when authorized" do
        pie = create(:mock_apple_pie, grandma: @grandma, ingredients: "allowed")
        expect(custom_controller.authorized?(:destroy, pie)).to be true
      end

      it "blocks destroy when unauthorized" do
        pie = create(:mock_apple_pie, grandma: @grandma, ingredients: "forbidden_ingredient")
        expect(custom_controller.authorized?(:destroy, pie)).to be false
      end

      it "allows show when authorized" do
        pie = create(:mock_apple_pie, grandma: @grandma, ingredients: "allowed")
        expect(custom_controller.authorized?(:show, pie)).to be true
      end

      it "blocks show when unauthorized" do
        pie = create(:mock_apple_pie, grandma: @grandma, ingredients: "secret_ingredient")
        expect(custom_controller.authorized?(:show, pie)).to be false
      end
    end

    describe "custom forbidden responses" do
      let(:custom_controller_class) do
        Class.new(MockApplePiesController) do
          def authorized?(_action, _resource = nil)
            false # Always unauthorized
          end

          def respond_as_forbidden
            redirect_to "/custom_forbidden"
          end
        end
      end

      it "uses custom forbidden response" do
        custom_controller = custom_controller_class.new
        custom_controller.current_grandma = @grandma
        @grandma.mock_apple_pies.first

        # Test that respond_as_forbidden is called (we can't easily test the full response in this setup)
        expect(custom_controller).to receive(:redirect_to).with("/custom_forbidden")
        custom_controller.respond_as_forbidden
      end
    end
  end
end
