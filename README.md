# Typical Situation [![Spec CI](https://github.com/apsislabs/typical_situation/workflows/Spec%20CI/badge.svg)](https://github.com/apsislabs/typical_situation/actions)

The missing Ruby on Rails ActionController REST API mixin. Originally forked from https://github.com/mars/typical_situation

A Ruby mixin (module) providing the seven standard resource actions & responses for an ActiveRecord :model_type & :collection.

## Installation

Tested in:

- Rails 7.2
- Rails 8.0
- Rails 8.1

Against Ruby versions:

- 3.1
- 3.2
- 3.3
- 3.4
- 4.0

Add to your **Gemfile**:

    gem 'typical_situation'

**Legacy Versions**: For Rails 4.x/5.x/6.x support, see older versions of this gem. Ruby 3.0+ is required.

## Usage

### Define your model and methods

Basic usage is to declare `typical_situation` and define the required `collection` helper. Member lookup uses the model's configured single-column primary key within the security-scoped collection. Missing identifiers return `nil` from the lookup and produce a 404 response.

```rb
class PostsController < ApplicationController
  include TypicalSituation

  # Symbolized, underscored version of the model to use as the resource.
  typical_situation :post # => maps to the Post model

  private

  # The collection of model instances.
  def collection
    current_user.posts
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
- [serialization](lib/typical_situation/serialization.rb) - resource representation and JSON root wrapping

#### Common Customization Hooks

Most customization hooks are intended to be overridden as `private` or `protected` controller methods so they do not become public controller actions.

For index actions, resources move through this pipeline:

1. `collection` - base relation from the host controller
2. `scoped_resource` - visibility/tenant/security scoping
3. `apply_filtering` - request-driven search and filter transforms
4. `apply_sorting` - default sorting from `default_sorting_attribute`
5. `paginate_resources` - pagination adapter hook
6. `prepare_resources` - post-process the loaded records

**Scoped Collections** - Restrict the base collection based on user permissions, tenancy, or other security boundaries. This scope applies to index and member lookup for show, edit, update, and destroy. Filtering, sorting, and pagination remain index-only. New/create use `collection`, so read-visibility conditions do not become creation defaults:

```ruby
def scoped_resource
  if current_user.admin?
    collection
  else
    collection.where(published: true)
  end
end
```

**Search and Filtering** - Apply request-driven filters after scoping and before sorting/pagination:

```ruby
def apply_filtering(resources)
  resources = resources.where(status: params[:status]) if params[:status].present?
  resources = resources.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
  resources
end
```

**Post-processing** - Mutate or decorate the final paginated record set (e.g. compute a derived attribute on every record):

```ruby
def prepare_resources(resources)
  resources.each { |post| post.current_user_liked = liked_post_ids.include?(post.id) }
end
```

**Custom Lookup** - Use different attributes for finding resources:

```ruby
def find_in_collection(resources, slug)
  resources.find_by(slug: slug)
end
```

The lookup receives `scoped_resource`; query that relation rather than `collection` to preserve security boundaries. Overriding `find_resource` replaces the security-aware lookup entirely.

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

#### Flash Messages

Add to `config/locales/en.yml`:

```yaml
en:
  typical_situation:
    flash:
      create:
        success: "%{resource} was successfully created"
      update:
        success: "%{resource} was successfully updated"
      destroy:
        success: "%{resource} was successfully deleted"
```

**Custom messages per resource:**

```yaml
en:
  posts:
    flash:
      create:
        success: "Your blog post is now live"
```

Override translation helper:

```ruby
def translate_with_resource(key)
  model_key = "#{resource_name}.flash.#{key}"
  if I18n.exists?(model_key)
    I18n.t(model_key, resource: resource_name.humanize)
  else
    I18n.t("typical_situation.flash.#{key}", resource: resource_name.humanize)
  end
end
```

**Custom flash logic:**

```ruby
def set_success_flash(action)
  case action
  when :create
    flash[:notice] = "Your #{resource_name.humanize.downcase} is live"
  when :destroy
    flash[:warning] = translate_with_resource("#{action}.success")
  end
end
```

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

`TypicalSituation` calls `as_json(root: false)` by default. Override `serializable_resource` to return an unrooted Ruby `Hash` for a member or an `Array` of resource data for a collection. Rails encodes the response once; returning an encoded JSON string raises `TypeError`.

`include_root?` controls wrapping with `model_type` for members and `plural_model_type` for collections. Error responses merge model errors under `errors`, independently of the custom serializer.

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
    MockApplePieResource.new(resource).to_h
  end

  def collection
    current_user.mock_apple_pies
  end
end
```

##### ActiveModelSerializers

```rb
class MockApplePieIndexSerializer < ActiveModel::Serializer
  attributes :id, :ingredients
end

module TypicalSituation
  module Serialization
    def serializable_resource(resource)
      if action_name == "index"
        ActiveModelSerializers::SerializableResource.new(
          resource,
          each_serializer: MockApplePieIndexSerializer,
          adapter: :attributes
        ).as_json
      else
        ActiveModelSerializers::SerializableResource.new(
          resource,
          adapter: :attributes
        ).as_json
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
    MockApplePieSerializer.new(resource).serializable_hash.fetch(:data)
  end
end
```

## Migrating Controller Hooks

These hook changes are breaking:

- Remove redundant `find_in_collection(id)` overrides, or change them to `find_in_collection(resources, id)` and query the supplied scoped relation.
- `update_resource(resource, attrs)` must return a success boolean. `create_resource` and `destroy_resource` still return resources; success is determined by `persisted?` and `destroyed?`, respectively. Callback aborts return 422 even when no validation errors were added.
- Overrides of `respond_as_created`, `respond_as_changed`, and `respond_as_gone` must accept the required `success:` keyword and pass it to `super` when delegating.
- HTML creation uses `created_so_redirect` and `after_resource_created_path`; updates continue using `changed_so_redirect` and `after_resource_updated_path`.
- Serialization methods now live in `TypicalSituation::Serialization`, not `Operations`. Return Ruby data from `serializable_resource`, not JSON strings or serializer objects. Overrides of `serialize_resource` should accept `errors: false` instead of an options hash.
- Failed operations preserve model errors or add `typical_situation.errors.operation_failed` when none exist. Failed HTML destruction sets the error flash; JSON failures do not set flash messages.

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

### Releasing

Create a release from `main`:

```sh
bin/release {major|minor|patch|pre}
git push --follow-tags
```

The release script validates the repository, bumps the version, creates a git tag.

Publishing to RubyGems and creating a GitHub Release are handled automatically by GitHub Actions.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/apsislabs/typical_situation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


---

# Built by Apsis

[![apsis](https://s3-us-west-2.amazonaws.com/apsiscdn/apsis.png)](https://www.apsis.io)

`typical_situation` was built by Apsis Labs. We love sharing what we build! Check out our [other libraries on Github](https://github.com/apsislabs), and if you like our work you can [hire us](https://www.apsis.io) to build your vision.
