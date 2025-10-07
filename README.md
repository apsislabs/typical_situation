# Typical Situation [![Spec CI](https://github.com/apsislabs/typical_situation/workflows/Spec%20CI/badge.svg)](https://github.com/apsislabs/typical_situation/actions)

The missing Ruby on Rails ActionController REST API mixin.

A Ruby mixin (module) providing the seven standard resource actions & responses for an ActiveRecord :model_type & :collection.

## Installation

Tested in:

- Rails 7.0
- Rails 7.1  
- Rails 8.0

Against Ruby versions:

- 3.0
- 3.1
- 3.2
- 3.3

Add to your **Gemfile**:

    gem 'typical_situation'

**Legacy Versions**: For Rails 4.x/5.x/6.x support, see older versions of this gem. Ruby 3.0+ is required.

## Usage

### Define your model and methods

**Modern syntax (recommended):**

    class MockApplePiesController < ApplicationController
      include TypicalSituation

      typical_situation :mock_apple_pie

      private

      # The collection of model instances.
      def collection
        current_user.mock_apple_pies
      end

      # Find a model instance by ID.
      def find_in_collection(id)
        collection.find_by_id(id)
      end
    end

**Legacy syntax (still supported):**

    class MockApplePiesController < ApplicationController
      include TypicalSituation

      # Symbolized, underscored version of the model (class) to use as the resource.
      def model_type
        :mock_apple_pie
      end

      private

      # The collection of model instances.
      def collection
        current_user.mock_apple_pies
      end

      # Find a model instance by ID.
      def find_in_collection(id)
        collection.find_by_id(id)
      end
    end

### Syntax Options

**`typical_situation` class method** - The recommended modern syntax that provides a clean, Rails-like declarative style.

**`model_type` instance method** - The original syntax that's still fully supported for backward compatibility.

Both syntaxes are functionally identical and can be used interchangeably. The `typical_situation` method is simply syntactic sugar that defines the `model_type` method under the hood.

### Get a fully functional REST API

The seven standard resourceful actions:

1. **index**
2. **show**
3. **new**
4. **create**
5. **edit**
6. **update**
7. **delete**

For the content types:

- **HTML**
- **JSON**

With response handling for:

- the collection
- a single instance
- not found
- validation errors (using ActiveModel::Errors format)
- changed
- deleted/gone

### Customize by overriding highly composable methods

`TypicalSituation` is composed of a library of common functionality, which can all be overridden in individual controllers. Express what is _different_ & _special_ about each controller, instead of repeating boilerplate.

The library is split into modules:

- [identity](https://github.com/mars/typical_situation/blob/master/lib/typical_situation/identity.rb) - **required definitions** of the model & how to find it
- [actions](https://github.com/mars/typical_situation/blob/master/lib/typical_situation/actions.rb) - high-level controller actions
- [operations](https://github.com/mars/typical_situation/blob/master/lib/typical_situation/operations.rb) - loading, changing, & persisting the model
- [responses](https://github.com/mars/typical_situation/blob/master/lib/typical_situation/responses.rb) - HTTP responses & redirects

#### Common Customization Hooks

**Scoped Collections** - Filter the collection based on user permissions or other criteria:

```ruby
def scoped_resource
  if current_user.admin?
    collection
  else
    collection.where(published: true)
  end
end
```

**Custom Lookup** - Use different attributes for finding resources:

```ruby
def find_resource(param)
  collection.find_by!(slug: param)
end
```

**Custom Redirects** - Control where users go after actions:

```ruby
def after_resource_created_path(resource)
  { action: :index }
end

def after_resource_updated_path(resource)
  edit_resource_path(resource)
end

def after_resource_destroyed_path(resource)
  { action: :index }
end
```

**Sorting** - Set default sorting for index pages:

```ruby
def default_sorting_attribute
  :created_at
end

def default_sorting_direction
  :desc
end
```

**Pagination** - Bring your own pagination solution:

```ruby
# Kaminari
def paginate_resources(resources)
  resources.page(params[:page]).per(params[:per_page] || 25)
end

# will_paginate
def paginate_resources(resources)
  resources.paginate(page: params[:page], per_page: params[:per_page] || 25)
end

# Custom pagination
def paginate_resources(resources)
  resources.limit(20).offset((params[:page].to_i - 1) * 20)
end
```

#### Authorization

Control access to resources by overriding the `authorized?` method:

```ruby
class PostsController < ApplicationController
  include TypicalSituation
  typical_situation :post

  private

  def authorized?(action, resource = nil)
    case action
    when :destroy, :update, :edit
      resource&.user == current_user || current_user&.admin?
    when :show
      resource&.published? || resource&.user == current_user
    else
      true
    end
  end
end
```

**CanCanCan**: `can?(action, resource || model_class)`

**Pundit**: `policy(resource || model_class).public_send("#{action}?")`

**Custom responses**:

```ruby
def respond_as_forbidden
  redirect_to login_path, alert: "Access denied"
end
```

#### Serialization

Under the hood `TypicalSituation` calls `to_json` on your `ActiveRecord` models. This isn't always the optimal way to serialize resources, though, and so `TypicalSituation` offers a simple means of overriding the base Serialization --- either on an individual controller, or for your entire application.

##### ActiveModelSerializers

To use `ActiveModelSerializers`, add an file an initializer called `typical_situation.rb` and override the `Operations` module:

    module TypicalSituation
      module Operations
        def serializable_resource(resource)
          ActiveModelSerializers::SerializableResource.new(resource)
        end
      end
    end

If you'd like to use different serializers per method, you can check `action_name` to determine your current controller endpoint.

    class MockApplePieIndexSerializer < ActiveModel::Serializer
      attributes :id, :ingredients
    end

    module TypicalSituation
      module Operations
        def serializable_resource(resource)
          if action_name == "index"
            ActiveModelSerializers::SerializableResource.new(
              resource,
              each_serializer: MockApplePieIndexSerializer
            )
          else
            ActiveModelSerializers::SerializableResource.new(resource)
          end
        end
      end
    end

##### Blueprinter

`Blueprinter` relies on calling a specific blueprint, it is better suited to being overriden at the controller level. To do so, in your controller file, simply override the `serializable_resource` method as below:

    class MockApplePieBlueprint < Blueprinter::Base
      identifier :id
      fields :ingredients
      association :grandma, blueprint: GrandmaBlueprint
    end

    class MockApplePiesController < ApplicationController
      include TypicalSituation

      def serializable_resource(resource)
        MockApplePieBlueprint.render(resource)
      end
    end

###### Fast JSON API

Like `Blueprinter`,

    class MockApplePieSerializer
      include FastJsonapi::ObjectSerializer
      attributes :ingredients
      belongs_to :grandma
    end

    class MockApplePiesController < ApplicationController
      include TypicalSituation

      def serializable_resource(resource)
        MockApplePieSerializer.new(resource).serializable_hash
      end
    end

##### Alba

[Alba](https://github.com/okuramasafumi/alba) is a fast, modern JSON serializer. Like `Blueprinter` and `Fast JSON API`, it's best suited to being overridden at the controller level:

    class MockApplePieResource
      include Alba::Resource

      attributes :id, :ingredients
      
      association :grandma, resource: GrandmaResource
    end

    class MockApplePiesController < ApplicationController
      include TypicalSituation
      typical_situation :mock_apple_pie

      private

      def serializable_resource(resource)
        MockApplePieResource.new(resource).serialize
      end

      def collection
        current_user.mock_apple_pies
      end

      def find_in_collection(id)
        collection.find_by_id(id)
      end
    end

## Legalese

This project uses MIT-LICENSE.
