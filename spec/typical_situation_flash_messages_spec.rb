# frozen_string_literal: true

require "spec_helper"

RSpec.describe TypicalSituation::FlashMessages do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include TypicalSituation

      typical_situation :mock_apple_pie

      def model_type
        :mock_apple_pie
      end

      def flash
        @flash ||= {}
      end
    end
  end

  let(:controller) { controller_class.new }
  let(:resource) { double(:resource, errors: double(:errors, any?: false, full_messages: [])) }

  before do
    controller.instance_variable_set(:@resource, resource)
  end

  describe "#set_success_flash" do
    it "sets translated flash message for create" do
      expect(I18n).to receive(:t).with(
        "typical_situation.flash.create.success",
        resource: "Mock apple pie"
      ).and_return("Mock apple pie was successfully created")

      controller.send(:set_success_flash, :create)
      expect(controller.flash[:notice]).to eq("Mock apple pie was successfully created")
    end

    it "sets translated flash message for update" do
      expect(I18n).to receive(:t).with(
        "typical_situation.flash.update.success",
        resource: "Mock apple pie"
      ).and_return("Mock apple pie was successfully updated")

      controller.send(:set_success_flash, :update)
      expect(controller.flash[:notice]).to eq("Mock apple pie was successfully updated")
    end

    it "sets translated flash message for destroy" do
      expect(I18n).to receive(:t).with(
        "typical_situation.flash.destroy.success",
        resource: "Mock apple pie"
      ).and_return("Mock apple pie was successfully deleted")

      controller.send(:set_success_flash, :destroy)
      expect(controller.flash[:notice]).to eq("Mock apple pie was successfully deleted")
    end
  end

  describe "#set_error_flash" do
    it "does nothing when resource has no errors" do
      controller.send(:set_error_flash)
      expect(controller.flash[:error]).to be_nil
    end

    it "does nothing when resource is nil" do
      controller.instance_variable_set(:@resource, nil)
      controller.send(:set_error_flash)
      expect(controller.flash[:error]).to be_nil
    end

    it "sets error flash when resource has errors" do
      allow(resource.errors).to receive(:any?).and_return(true)
      allow(resource.errors).to receive(:full_messages).and_return(["Name can't be blank", "Email is invalid"])

      controller.send(:set_error_flash)
      expect(controller.flash[:error]).to eq("Name can't be blank, Email is invalid")
    end
  end

  describe "#translate_with_resource" do
    it "translates with proper resource interpolation" do
      expect(I18n).to receive(:t).with(
        "typical_situation.flash.create.success",
        resource: "Mock apple pie"
      ).and_return("Mock apple pie was successfully created")

      result = controller.send(:translate_with_resource, "create.success")
      expect(result).to eq("Mock apple pie was successfully created")
    end
  end
end
