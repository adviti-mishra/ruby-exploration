
require 'mongoid'

Mongoid.connect_to 'mongoid-5658'
Mongoid.purge!

Mongoid.around_callbacks_for_embeds = true

class Foo
  include Mongoid::Document
  embeds_many :bars, cascade_callbacks: true
end

class Bar
  include Mongoid::Document
  embedded_in :foo
end

foo = Foo.new
1500.times { foo.bars.build }
foo.save
