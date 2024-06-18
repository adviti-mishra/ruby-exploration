require 'fiber'

module Callbacks
  def self.included(base)
    base.extend ClassMethods
  end

  def invoke_with_callbacks(&callback)
    self.class.invoke_with_callbacks(self, &callback)
  end

  module ClassMethods
    def before_action(*methods)
      callbacks[:before].concat(methods)
    end

    def around_action(*methods)
      # TODO: make this an instance variable [list]
      callbacks[:around].concat(methods)
    end

    def after_action(*methods)
      # TODO: make this an instance variable [list]
      callbacks[:after].concat(methods)
    end

    def invoke_with_callbacks(instance, &callback)
      execute_callbacks_until_a_potential_yield(instance)
      callback.call
      execute_any_callbacks_after_a_potential_yield(instance)
    end

    private

    def callbacks
      @callbacks ||= { before: [], around: [], after: [] }
    end

    def around_fibers
      @around_fibers ||= []
    end

    def execute_callbacks_until_a_potential_yield(instance)

      execute_before_callbacks(instance)

      if callbacks[:around].any?
        callbacks[:around].each do |cb|
          fiber = Fiber.new do
            instance.send(cb) do
              Fiber.yield
              execute_after_callbacks(instance)
            end
          end
          around_fibers << fiber # can be resumed later for after and around (after)
          fiber.resume
        end
      else
        execute_after_callbacks(instance)
      end

      instance.children.each do |child|
        execute_callbacks_until_a_potential_yield(child)
      end
    end

    def execute_any_callbacks_after_a_potential_yield(instance)
      around_fibers.reverse_each(&:resume)
    end

    def execute_before_callbacks(instance)
      callbacks[:before].each do |cb|
        instance.send(cb) if instance.respond_to?(cb, true)
      end
    end

    def execute_after_callbacks(instance)
      callbacks[:after].each do |acb|
        instance.send(acb) if instance.respond_to?(acb, true)
      end
    end

  end
end

class A
  include Callbacks

  before_action :before
  around_action :around
  after_action :after

  attr_reader :who_am_i, :children
  attr_accessor :around_fibers

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
    A.new('grand-child #1'),
    A.new('grand-child #2'),
    A.new('grand-child #3')
  ]),
  A.new('child #2', children: [
    A.new('grand-child #4'),
    A.new('grand-child #5')
  ]),
  A.new('child #3'),
  A.new('child #4', children: [
    A.new('grand-child #6'),
    A.new('grand-child #7'),
    A.new('grand-child #8', children: [
      A.new('great-grand-child #1')
    ])
  ])
])

root.do_the_thing
