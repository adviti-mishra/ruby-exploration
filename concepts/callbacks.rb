require 'mongoid'

Mongoid.connect_to 'walkthru'
Mongoid.purge!

class Book
  include Mongoid::Document

  before_validation { puts "before_validation" }
  before_create { puts "before_create" }
  before_save { puts "before_save" }
  before_update { puts "before_update" }
  before_destroy { puts "before_destroy" }

  after_validation { puts "after_validation" }
  after_create { puts "after_create" }
  after_save { puts "after_save" }
  after_update { puts "after_update" }
  after_destroy { puts "after_destroy" }

  around_create  :log_around_create
  around_save :log_around_save
  around_update :log_around_update
  around_destroy :log_around_destroy

  field :title, type: String
  validates_uniqueness_of :title

  private

  def log_around_create
    puts "around_create BEGIN"
    yield
    puts "around_create END"
  end

  def log_around_save
    puts "around_save BEGIN"
    yield
    puts "around_save END"
  end

  def log_around_update
    puts "around_update BEGIN"
    yield
    puts "around_update END"
  end
end


=begin
CREATE steps
book = Book.new(title: "Harry Potter 1")
book.save
OR
book = Book.create!(title: "Harry Potter 1")
=end


=begin
UPDATE steps
book.title = "Harry Potter 2"
book.save
=end

=begin
DESTROY steps
book.destroy
=end
