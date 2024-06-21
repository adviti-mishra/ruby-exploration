module Cream
  def cream?
    return true
  end
end

class Cookie
  include Cream
end

c = Cookie.new
puts c.cream?

# modules are things that hold methods, just like classes do.
# However, modules can not be instantiated. I.e.,
# it is not possible to create objects from a module.
# With modules you can share methods between classes: Modules
# can be included into classes, and this makes their methods
# available on the class, just as if we’d copied and pasted
# these methods over to the class definition.
