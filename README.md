# Typical Situation [![Spec CI](https://github.com/apsislabs/typical_situation/workflows/Spec%20CI/badge.svg)](https://github.com/apsislabs/typical_situation/actions)

The missing Ruby on Rails ActionController REST API mixin.

A Ruby mixin (module) providing the seven standard resource actions & responses for an ActiveRecord :model_type & :collection.

## Installation

Tested in:

- Rails 7.0
- Rails 7.1  
- Rails 8.0

Against Ruby versions:

- 3.1
- 3.2
- 3.3
- 3.4

Add to your **Gemfile**:

    gem 'typical_situation'

**Legacy Versions**: For Rails 4.x/5.x/6.x support, see older versions of this gem. Ruby 3.0+ is required.

## Usage

### Define your model and methods

Basic usage is to declare the `typical_situation`, and then two required helper methods. Everything else is handled automatically.

```rb
class PostsController < ApplicationController
  include TypicalSituation

  typical_situation :post # => maps to the Post model

  private

  # The collection of model instances.
  def collection
    current_user.posts
  end

  # Find a model instance by ID.
  def find_in_collection(id)
    collection.find_by_id(id)
  end
end
```

There are two alternative helper methods:

#### Typical REST

The typical REST helper is an alias for `typical_situation`, and defines the 7 standard REST endpoints: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`.

```rb
class PostsController < ApplicationController
  include TypicalSituation

  typical_rest :post

  ...
end
```

#### Typical CRUD

Sometimes you don't need all seven endpoints, and just need standard CRUD. The typical CRUD helper defines the 4 standard CRUD endpoints: `create`, `show`, `update`, `destroy`.

```rb
class PostsController < ApplicationController
  include TypicalSituation

  typical_crud :post

  ...
end
```

#### Customizing defined endpoints

You can also define only the endpoints you want by passing an `only` flag to `typical_situation`:

```rb
class PostsController < ApplicationController
  include TypicalSituation

  typical_situation :post, only: [:index, :show]

  ...
end
```

### Customize by overriding highly composable methods

`TypicalSituation` is composed of a library of common functionality, which can all be overridden in individual controllers. Express what is _different_ & _special_ about each controller, instead of repeating boilerplate.

The library is split into modules:

- [identity](https://github.com/mars/typical_situation/blob/master/lib/typical_situation/identity.rb) - **required definitions** of the model & how to find it
- [actions](https://github.com/mars/typical_situation/blob/master/lib/typical_situation/actions.rb) - high-level controller actions
- [operations](https://github.com/mars/typical_situation/blob/master/lib/typical_situation/operations.rb) - loading, changing, & persisting the model
- [permissions](https://github.com/mars/typical_situation/blob/master/lib/typical_situation/permissions.rb) - handling authorization to records and actions
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

**Strong Parameters** - Control which parameters are allowed for create and update operations:

```ruby
class PostsController < ApplicationController
  include TypicalSituation
  typical_situation :post

  private

  # Only allow title and content for new posts
  def permitted_create_params
    [:title, :content]
  end

  # Allow title, content, and published for updates
  def permitted_update_params
    [:title, :content, :published]
  end
end
```

By default, `TypicalSituation` permits all parameters (`permit!`) when these methods return `nil` or an empty array. Override them to restrict parameters for security.

#### Authorization

Control access to resources by overriding the `authorized?` method:

```rb
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

You can also customize the response when authorization is denied:

```rb
def respond_as_forbidden
  redirect_to login_path, alert: "Access denied"
end
```

##### CanCanCan

```rb
def authorized?(action, resource = nil)
  can?(action, resource || model_class)
end
```

##### Pundit

```rb
def authorized?(action, resource = nil)
  policy(resource || model_class).public_send("#{action}?")
end
```

#### Serialization

Under the hood `TypicalSituation` calls `to_json` on your `ActiveRecord` models. This isn't always the optimal way to serialize resources, though, and so `TypicalSituation` offers a simple means of overriding the base Serialization --- either on an individual controller, or for your entire application.

##### Alba

```rb
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
```

##### ActiveModelSerializers

```rb
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
```

###### Fast JSON API

```rb
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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Local Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Install appraisal gemfiles for testing across Rails versions:
   ```bash
   bundle exec appraisal install
   ```

### Running Tests

Tests are written using [RSpec](https://rspec.info/) and are setup to use [Appraisal](https://github.com/thoughtbot/appraisal) to run tests over multiple Rails versions.

Run all tests across all supported Rails versions:
```bash
bundle exec appraisal rspec
```

Run tests for a specific Rails version:
```bash
bundle exec appraisal rails_7.0 rspec
bundle exec appraisal rails_7.1 rspec
bundle exec appraisal rails_8.0 rspec
```

Run specific test files:
```bash
bundle exec rspec spec/path/to/spec.rb
bundle exec appraisal rails_7.0 rspec spec/path/to/spec.rb
```

### Linting and Formatting

This project uses [Standard Ruby](https://github.com/testdouble/standard) for code formatting and linting.

Check for style violations:
```bash
bundle exec standardrb
```

Automatically fix style violations:
```bash
bundle exec standardrb --fix
```

Run both linting and tests (the default rake task):
```bash
bundle exec rake
```

### Console

Start an interactive console to experiment with the gem:
```bash
bundle exec irb -r typical_situation
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/apsislabs/typical_situation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Legal Disclaimer

Apsis Labs, LLP is not a law firm and does not provide legal advice. The information in this repo and software does not constitute legal advice, nor does usage of this software create an attorney-client relationship.

---

# Built by Apsis

[![apsis](https://s3-us-west-2.amazonaws.com/apsiscdn/apsis.png)](https://www.apsis.io)

`typical_situation` was built by Apsis Labs. We love sharing what we build! Check out our [other libraries on Github](https://github.com/apsislabs), and if you like our work you can [hire us](https://www.apsis.io) to build your vision.
