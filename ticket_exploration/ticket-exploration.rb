require 'fiber'

module Callbacks
  def self.included(base)
    base.extend ClassMethods
  end

  def invoke_with_callbacks(&callback)
    self.class.invoke_with_callbacks(self, &callback)
  end

  module ClassMethods
    def callbacks
      @callbacks ||= []
    end

    def before_action(*methods)
      callbacks.concat(methods.map { |cb| prepare_callback(cb, :before) })
    end

    def around_action(*methods)
      callbacks.concat(methods.map { |cb| prepare_callback(cb, :around) })
    end

    def after_action(*methods)
      callbacks.concat(methods.map { |cb| prepare_callback(cb, :after) })
    end

    def invoke_with_callbacks(instance)
      realized_callbacks = collect_callback_tree(instance)

      realized_callbacks.each do |cb|
        return if cb.resume == false
      end

      yield

      realized_callbacks.reverse_each(&:resume)
    end

    private

    def collect_callback_tree(instance, list: [])
      callbacks.each { |cb| list << cb[instance] }
      instance.children.each { |child| collect_callback_tree(child, list: list) }
      list
    end

    def prepare_callback(callback, which)
      Proc.new { |instance| send(:"#{which}_callback_for", instance, callback) }
    end

    # Returns a fiber that invokes the callback the first time the fiber is resumed
    # (returning the callback's return value), and returns nil the second time.
    def before_callback_for(instance, callback)
      Fiber.new { Fiber.yield instance.send(callback); nil }
    end

    # Returns a fiber that invokes the callback the first time the fiber is resumed,
    # pausing when the callback yields, and resumes from the yield when the fiber is
    # resumed the second time.
    def around_callback_for(instance, callback)
      Fiber.new { instance.send(callback) { Fiber.yield }; nil }
    end

    # Returns a fiber that returns nil the first time it is resumed, and invokes the
    # callback the second time it is resumed.
    def after_callback_for(instance, callback)
      Fiber.new { Fiber.yield; instance.send(callback) }
    end
  end
end

class A
  include Callbacks

  before_action :before
  around_action :around
  after_action  :after

  attr_reader :who_am_i, :children

  def initialize(who_am_i, children: [])
    @who_am_i = who_am_i
    @children = children
  end

  def do_the_thing
    invoke_with_callbacks do
      puts "[#{who_am_i}] *** doing the thing! ***"
    end
  end

  private

  def before
    puts "[#{who_am_i}] before"
  end

  def around
    puts "[#{who_am_i}] around (before)"
    yield
    puts "[#{who_am_i}] around (after)"
  end

  def after
    puts "[#{who_am_i}] after"
  end
end

root = A.new('root', children: [
  A.new('child #1', children: [
    A.new('grandchild #1'),
    A.new('grandchild #2'),
    A.new('grandchild #3')
  ]),
  A.new('child #2', children: [
    A.new('grandchild #4'),
    A.new('grandchild #5')
  ]),
  A.new('child #3'),
  A.new('child #4', children: [
    A.new('grandchild #6'),
    A.new('grandchild #7'),
    A.new('grandchild #8', children: [
      A.new('great-grandchild #1')
    ])
  ])
])

root.do_the_thing
