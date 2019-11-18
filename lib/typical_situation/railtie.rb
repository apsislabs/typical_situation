# frozen_string_literal: true

require 'typical_situation'
require 'rails'

module TypicalSituation
  class Railtie < Rails::Railtie
    initializer 'typical_situation.initialize' do |_app|
      ActiveSupport.on_load(:active_record) do
        ActionController::Base.send :include, TypicalSituation::Controller
      end
    end
  end
end