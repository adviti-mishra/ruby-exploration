# Functions dealing with callbacks across Rails and Mongoid 

## Rails: ActiveSupport::Callbacks 

```ruby 
def define_callbacks(*names)
  options = names.extract_options!

  names.each do |name|
    name = name.to_sym

    ([self] + self.descendants).each do |target|
      target.set_callbacks name, CallbackChain.new(name, options)
    end

    module_eval <<-RUBY, __FILE__, __LINE__ + 1
      def _run_#{name}_callbacks(&block)
        run_callbacks #{name.inspect}, &block
      end

      def self._#{name}_callbacks
        get_callbacks(#{name.inspect})
      end

      def self._#{name}_callbacks=(value)
        set_callbacks(#{name.inspect}, value)
      end

      def _#{name}_callbacks
        __callbacks[#{name.inspect}]
      end
    RUBY
  end
end
```
### Purpose: <br/>
When you define callbacks in a model, such as before_validation or after_validation, Rails internally uses define_callbacks to set up these callbacks. For example, 
```ruby
class MyModel < ApplicationRecord
  before_validation : log_validate

  private

  def log_validate
    # Some validation logic
  end
end
```
Here, the before_validation callback log_validate will be added to the :validate callback chain for MyModel.


### Explanation (syntax): <br/>
```ruby 
names.each do |name|
```
Loops over each callback name provided

#### 1. Converts the name to a symbol for consistency 
```ruby 
name = name.to_sym
```
#### 2. Sets callback chains 
```ruby 
 ([self] + self.descendants).each do |target|
      target.set_callbacks name, CallbackChain.new(name, options)
    end
```
Ensures that the callback chain is set not only for the current class but for all its descendants. CallbackChain.new(name,options) initializes a new CallbackChain object for the given name and options. 

#### 3. Define methods dynamically 
```ruby 
module_eval <<-RUBY, __FILE__, __LINE__ + 1
  def _run_#{name}_callbacks(&block)
    run_callbacks #{name.inspect}, &block
  end

  def self._#{name}_callbacks
    get_callbacks(#{name.inspect})
  end

  def self._#{name}_callbacks=(value)
    set_callbacks(#{name.inspect}, value)
  end

  def _#{name}_callbacks
    __callbacks[#{name.inspect}]
  end
RUBY
```
This dynamically defines methods within the context of the current module or class ('self')
The defined methods are: 
##### 3.1: _run_#{name}_callbacks(&block)
This executes the run_callbacks method to trigger the callbacks by calling <br/>
run_callbacks #{name.inspect}, &block
##### 3.2 self._#{name}_callbacks
returns the callback chain associated with 'name' by calling <br/>
get_callbacks(#{name.inspect})
##### 3.3 self._#{name}_callbacks=
sets the callback chain associated with 'name'
##### 3.4 _#{name}_callbacks
access the callback chain associated with 'name' stored in __callbacks 

## Mongoid: Mongoid::Interceptable 

### run_callbacks 
```ruby
    # Run the callbacks for the document. This overrides active support's
    # functionality to cascade callbacks to embedded documents that have been
    # flagged as such.
    #
    # @example Run the callbacks.
    #   run_callbacks :save do
    #     save!
    #   end
    #
    # @param [ Symbol ] kind The type of callback to execute.
    # @param [ true | false ] with_children Flag specifies whether callbacks
    #   of embedded document should be run.
    # @param [ Proc | nil ] skip_if If this proc returns true, the callbacks
    #   will not be triggered, while the given block will be still called.
    def run_callbacks(kind, with_children: true, skip_if: nil, &block)
      if skip_if&.call
        return block&.call
      end
      if with_children
        cascadable_children(kind).each do |child|
          if child.run_callbacks(child_callback_type(kind, child), with_children: with_children) == false
            return false
          end
        end
      end
      if callback_executable?(kind)
        super(kind, &block)
      else
        true
      end
    end
```

### _mongoid_run_child_callbacks 

```ruby 
    # Run the callbacks for embedded documents.
    #
    # @param [ Symbol ] kind The type of callback to execute.
    # @param [ Array<Document> ] children Children to execute callbacks on. If
    #   nil, callbacks will be executed on all cascadable children of
    #   the document.
    #
    # @api private
    def _mongoid_run_child_callbacks(kind, children: nil, &block)
      if Mongoid::Config.around_callbacks_for_embeds
        _mongoid_run_child_callbacks_with_around(kind, children: children, &block)
      else
        _mongoid_run_child_callbacks_without_around(kind, children: children, &block)
      end
    end
```


### _mongoid_run_child_callbacks_with_around

```ruby 
   # Execute the callbacks of given kind for embedded documents including
    # around callbacks.
    #
    # @note This method is prone to stack overflow errors if the document
    #   has a large number of embedded documents. It is recommended to avoid
    #   using around callbacks for embedded documents until a proper solution
    #   is implemented.
    #
    # @param [ Symbol ] kind The type of callback to execute.
    # @param [ Array<Document> ] children Children to execute callbacks on. If
    #  nil, callbacks will be executed on all cascadable children of
    #  the document.
    #
    #  @api private
    def _mongoid_run_child_callbacks_with_around(kind, children: nil, &block)
      child, *tail = (children || cascadable_children(kind))
      with_children = !Mongoid::Config.prevent_multiple_calls_of_embedded_callbacks
      if child.nil?
        block&.call
      elsif tail.empty?
        child.run_callbacks(child_callback_type(kind, child), with_children: with_children, &block)
      else
        child.run_callbacks(child_callback_type(kind, child), with_children: with_children) do
          _mongoid_run_child_callbacks_with_around(kind, children: tail, &block)
        end
      end
    end
```

### _mongoid_run_child_callbacks_without_around

```ruby
    # Execute the callbacks of given kind for embedded documents without
    # around callbacks.
    #
    # @param [ Symbol ] kind The type of callback to execute.
    # @param [ Array<Document> ] children Children to execute callbacks on. If
    #   nil, callbacks will be executed on all cascadable children of
    #   the document.
    #
    # @api private
    def _mongoid_run_child_callbacks_without_around(kind, children: nil, &block)
      children = (children || cascadable_children(kind))
      callback_list = _mongoid_run_child_before_callbacks(kind, children: children)
      return false if callback_list == false
      value = block&.call
      callback_list.each do |_next_sequence, env|
        env.value &&= value
      end
      return false if _mongoid_run_child_after_callbacks(callback_list: callback_list) == false

      value
    end
```

