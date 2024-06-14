# Proof of Concept: Fiber callbacks
An exploration of implementing callbacks with Ruby Fibers.  

## Interface 
```ruby
module Callbacks 
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods 
    def callbacks 
    def before_action(*methods)
    def around_action(*methods)
    def after_action(*methods)
    def invoke_with_callbacks(instance)
    private: 
    def collect_callback_tree(callback, which)
    def before_callback_for(instance, callback)
    def around_callback_for(instance, callback)
    def after_callback_for(instance, callback)
  end 
end
```

## Implementation 

### 1. module Callbacks 

#### Callbacks::self.included(base)
```ruby 
 def self.included(base)
    base.extend ClassMethods
  end
```
When this Callbacks module is included by `include Callbacks`, this method gets invoked. It's a lifecycle method you can put on modules. `base` in this case is going to be the base class that includes Callbacks. We are going to 'extend' it with the ClassMethods. This is one way of adding class-level methods to a class via a module. Otherwise, you'd have to do 
```ruby
include Callbacks # would put the instance methods on
extend Callbacks::ClassMethods # to get access to the class methods
```

####  Callbacks::invoke_with_callbacks(&callback)

```ruby 
def invoke_with_callbacks(&callback)
  self.class.invoke_with_callbacks(self, &callback)
end
```
This is the instance-level method we are adding to the ```base``` class. ```self.class.invoke_with_callbacks(self, &callback)``` calls the class method ```invoke_with_callbacks(instance)```

It keeps a list of callbacks, all the methods that are passed to it

### 2. module ClassMethods 

#### def callbacks
```ruby 
def callbacks
  @callbacks || = []
end
```
* ```@callbacks``` is an instance variable. <br/>
* ```|| = ``` is a conditional assignment operator. <br /> 
This assigns the value on the RHS, [] to ```@callbacks``` if ```@callbacks``` is nil or false

#### def before_action
```ruby
def before_action(*methods)
  callbacks.concat(methods.map { |cb|  prepare_callback(cb, :before)})
end
```
* ```def before_action(*methods)``` </br>
Takes any number of arguments. The arguments are then collected into an array anmed methods
*  ```callbacks.concat(methods.map { |cb| prepare_callback(cb, :before)})```</br> Maps over the methods array where each element cb is a symbol representing a method name. For each method name (cb), it calls prepare_callback(cb, :before)

#### def around_action(*methods)
Same as 2.2 but with prepare_callback(cb, :around)

#### def after_action(*methods)
Same as 2.4 but with prepare_callback(cb, :after)

#### def invoke_with_callbacks(instance)

### private methods: 

#### def collect_callback_tree(instance, list: [])

#### def prepare_callback(callback, which)

```ruby 
def prepare_callback(callback, which)
  Proc.new{ |instance| send(:"#{which}_callback_for", instance, callback)}
end
```
* ``` def prepare_callback(callback, which)``` <br/>
  * ```callback```: method name <br />
  * ```which```: type; one of [:before, :after, :around] <br />
* ``` Proc.new{ |instance| send(:"#{which}_callback_for", instance, callback)}``` <br/>
  * ```Proc.new``` creates a new Proc - an encapusalted block of code
  * ```"#{which}_callback_for"``` dynamically constructs a symbol representing the method name based on the which parameter
  * ```send``` is a Ruby method that calls the corresponding x_callback_for method by name with `instance` and `callback` as arguments. This method is called on the current object (`self`) which is the class that extends ClassMethods.
This block of code is returned

#### def before_callback_for(instance, callback)

#### def around_callback_for(instance, callback)

#### def after_callback_for(instance, callback)


