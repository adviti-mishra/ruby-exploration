
fiber = Fiber.new do
  Fiber.yield 1
  2
end

puts fiber.resume # 1 is returned @line3 and printed
puts fiber.resume # execution resumes @line4, 2 is returned and printed
# puts fiber.resume # `resume': attempt to resume a terminated fiber (FiberError) because the code of the fiber is done being executed

fiber2 = Fiber.new do |first|
  second = Fiber.yield first + 2
end

puts fiber2.resume 10 # 1st resume: passed as block argument. Fiber.yield 10+2 @line12 results in 12 being returned and printed
puts fiber2.resume 1_000_0000 # 2nd+ resume: becomes the return value of Fiber.yield. second becomes 1_000_000 @line12. This gets returned and printed
puts fiber.resume "The fiber will be dead before I can cause trouble" # `resume': attempt to resume a terminated fiber (FiberError) because the code of the fiber is done being executed
