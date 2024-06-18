# https://chaim-zalmy-muskal.medium.com/write-your-own-macros-and-create-your-own-gems-in-ruby-999b44186f25

class Student

  #attr_reader :name, :age # macro for generating a getter method
  #attr_writer :name, :age # macro for generating a setter method
  attr_accessor :name, :age # macro for generating a getter and a setter method

  def initialize(name, age)
    @name = name
    @age = age
  end

=begin
  # getter methods
  def name
    @name
  end

  def age
    @age
  end

  # setter methods
  def name=(name)
    @name = name
  end

  def age=(age)
    @age = age
  end
=end

end

stud2 = Student .new("Ferb", 12)
p "Name and age set by the initialization method: "
p stud2.name
p stud2.age
p "Name and age CHANGED by macro setters"
stud2.name = "Phineas"
stud2.age = 13
p "Name and age fetched by macro getters "
p stud2.name
p stud2.age

# https://shaqqour.medium.com/understanding-the-basics-of-macros-in-ruby-programming-13929a366075
