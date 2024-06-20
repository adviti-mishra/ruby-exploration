
# creatable.rb 

```ruby 
def create(attributes = nil, &block)
  _creating do
    if attributes.is_a?(::Array)
      attributes.map { |attrs| create(attrs, &block) }
    else
      doc = new(attributes, &block)
      doc.save
      doc
    end
  end
end
```

_creating ensures the enclosed code runs within a specific context

# doc = new(attributes, &block)
_______
```ruby
doc = new(attributes, &block)
```

## document.rb
________
```ruby
def initialize(attrs = nil, &block)
  construct_document(attrs, &block)
end
```
______
```ruby
def construct_document(attrs = nil, options = {})
  execute_callbacks = options.fetch(:execute_callbacks, Threaded.execute_callbacks?)

  self._parent = nil
  _building do
    prepare_to_process_attributes

    process_attributes(attrs) do
      yield(self) if block_given?
    end
    @attributes_before_type_cast = @attributes.merge(attributes_before_type_cast)

    resolve_post_construction_callbacks(execute_callbacks)
  end
  self
end
```
execute_callbacks = true <br/>
process attribute stuff <br/>
resolve_post_construction_callbacks(execute_callbacks)

```ruby 
def resolve_post_construction_callbacks(execute_callbacks)
  if execute_callbacks
    apply_post_processed_defaults
    run_callbacks(:initialize) unless _initialize_callbacks.empty?
  else
    pending_callbacks << :apply_post_processed_defaults
    pending_callbacks << :initialize
  end
end
```
run_callbacks(:initialize) unless _initialize_callbacks.empty? skipped over because there aren't any initialize callbacks defined

# doc.save

## savable.rb
```ruby 
# Save the document - will perform an insert if the document is new, and
# update if not.
#
# @example Save the document.
#   document.save
#
# @param [ Hash ] options Options to pass to the save.
#
# @option options [ true | false ] :touch Whether or not the updated_at
#   attribute will be updated with the current time. When this option is
#   false, none of the embedded documents will be touched. This option is
#   ignored when saving a new document, and the created_at and updated_at
#   will be set to the current time.
#
# @return [ true | false ] True if success, false if not.
def save(options = {})
  if new_record?
    !insert(options).new_record?
  else
    update_document(options)
  end
end
```

!insert(options).new_record?
## creatable.rb 
```ruby 
  # Insert a new document into the database. Will return the document
  # itself whether or not the save was successful.
  #
  # @example Insert a document.
  #   document.insert
  #
  # @param [ Hash ] options Options to pass to insert.
  #
  # @return [ Document ] The persisted document.
  def insert(options = {})
    prepare_insert(options) do
      if embedded?
        insert_as_embedded
      else
        insert_as_root
      end
    end
  end
```
prepare_insert(options)
```ruby 
  # @api private
  #
  # @example Prepare for insertion.
  #   document.prepare_insert do
  #     collection.insert(as_document)
  #   end
  #
  # @param [ Hash ] options The options.
  #
  # @return [ Document ] The document.
  def prepare_insert(options = {})
    raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
    return self if performing_validations?(options) &&
      invalid?(options[:context] || :create)
    ensure_client_compatibility!
    run_callbacks(:commit, with_children: true, skip_if: -> { in_transaction? }) do
      run_callbacks(:save, with_children: false) do
        run_callbacks(:create, with_children: false) do
          run_callbacks(:persist_parent, with_children: false) do
            _mongoid_run_child_callbacks(:save) do
              _mongoid_run_child_callbacks(:create) do
                result = yield(self)
                if !result.is_a?(Document) || result.errors.empty?
                  post_process_insert
                  post_process_persist(result, options)
                end
              end
            end
          end
        end
      end
    end
    self
  end
```
 return self if performing_validations?(options) &&
      invalid?(options[:context] || :create)

## validatable.rb
```ruby 
# Given the provided options, are we performing validations?
#
# @example Are we performing validations?
#   document.performing_validations?(validate: true)
#
# @param [ Hash ] options The options to check.
#
# @option options [ true | false ] :validate Whether or not to validate.
#
# @return [ true | false ] If we are validating.
def performing_validations?(options = {})
  options[:validate].nil? ? true : options[:validate]
end
```

# RAILS 

## Validators.rb 
```ruby 
 # Performs the opposite of <tt>valid?</tt>. Returns +true+ if errors were
    # added, +false+ otherwise.
    #
    #   class Person
    #     include ActiveModel::Validations
    #
    #     attr_accessor :name
    #     validates_presence_of :name
    #   end
    #
    #   person = Person.new
    #   person.name = ''
    #   person.invalid? # => true
    #   person.name = 'david'
    #   person.invalid? # => false
    #
    # Context can optionally be supplied to define which callbacks to test
    # against (the context is defined on the validations using <tt>:on</tt>).
    #
    #   class Person
    #     include ActiveModel::Validations
    #
    #     attr_accessor :name
    #     validates_presence_of :name, on: :new
    #   end
    #
    #   person = Person.new
    #   person.invalid?       # => false
    #   person.invalid?(:new) # => true
    def invalid?(context = nil)
      !valid?(context)
    end
```

```ruby 
def valid?(context = nil)
  current_context, self.validation_context = validation_context, context
  errors.clear
  run_validations!
ensure
  self.validation_context = current_context
end
```
run_validations!
```ruby 
def run_validations!
  _run_validate_callbacks
  errors.empty?
end
```
## ActiveSupport::Callbacks
_run_validate_callbacks defined
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
run_callbacks validate, &block is called  <br/>
### Define Callbacks: <br/>
When you define callbacks in a model, such as before_validation or after_validation, Rails internally uses define_callbacks to set up these callbacks.

```ruby
class MyModel < ApplicationRecord
  before_validation : log_validate

  private

  def log_validate
    # Some validation logic
  end
end
```
In the above example, the before_validation callback will be added to the :validate callback chain for MyModel.

### Store Callbacks in __callbacks:
The __callbacks hash for MyModel will have an entry for :validate, which is a CallbackChain object containing the do_something method. The CallbackChain object maintains the order of the callbacks defined for validate for e.g. before_validate_1, before_validate_2, after_validate1, after_validate2, etc. 

# MONGOID 

### Running Callbacks:
When run_callbacks(:validate) is called, it looks up the :validate entry in __callbacks and executes the callbacks in the chain. HOWEVER, MONGOID OVERWRITES RUN_CALLBACKS SO THAT IS EXECUTED. 

### Mongoid version: 
```Ruby 
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

### Rails version:
```ruby 
 # Runs the callbacks for the given event.
    #
    # Calls the before and around callbacks in the order they were set, yields
    # the block (if given one), and then runs the after callbacks in reverse
    # order.
    #
    # If the callback chain was halted, returns +false+. Otherwise returns the
    # result of the block, +nil+ if no callbacks have been set, or +true+
    # if callbacks have been set but no block is given.
    #
    #   run_callbacks :save do
    #     save
    #   end
    #
    #--
    #
    # As this method is used in many places, and often wraps large portions of
    # user code, it has an additional design goal of minimizing its impact on
    # the visible call stack. An exception from inside a :before or :after
    # callback can be as noisy as it likes -- but when control has passed
    # smoothly through and into the supplied block, we want as little evidence
    # as possible that we were here.
    def run_callbacks(kind, type = nil)
      callbacks = __callbacks[kind.to_sym]

      if callbacks.empty?
        yield if block_given?
      else
        env = Filters::Environment.new(self, false, nil)

        next_sequence = callbacks.compile(type)

        # Common case: no 'around' callbacks defined
        if next_sequence.final?
          next_sequence.invoke_before(env)
          env.value = !env.halted && (!block_given? || yield)
          next_sequence.invoke_after(env)
          env.value
        else
          invoke_sequence = Proc.new do
            skipped = nil

            while true
              current = next_sequence
              current.invoke_before(env)
              if current.final?
                env.value = !env.halted && (!block_given? || yield)
              elsif current.skip?(env)
                (skipped ||= []) << current
                next_sequence = next_sequence.nested
                next
              else
                next_sequence = next_sequence.nested
                begin
                  target, block, method, *arguments = current.expand_call_template(env, invoke_sequence)
                  target.send(method, *arguments, &block)
                ensure
                  next_sequence = current
                end
              end
              current.invoke_after(env)
              skipped.pop.invoke_after(env) while skipped&.first
              break env.value
            end
          end

          invoke_sequence.call
        end
      end
    end

```