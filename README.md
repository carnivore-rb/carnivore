# Carnivore

Eat messages, rule the world.

## Purpose

Slim library to consume messages. Sources are defined
and callbacks are registered to defined sources. Sources
feed messages to callback workers asynchronously and
stuff gets done. Super simple!

## Usage

1. Build a source
2. Add callbacks
3. Profit!

```ruby
Carnivore.configure do
  src = Source.build(:type => :test, :args => {})
  src.add_callback(:print_message) do |msg|
    puts "Received message: #{message}"
  end
end.start!
```

### Advanced Usage

Under the hood, callbacks are built into `Carnivore::Callback`
instances. This class can be subclassed and provided directly
instead of a simple block. This has the added bonus of being
able to define the number of worker instances to be created
for the callback (blocks default to 1):

```ruby
require 'carnivore'

class CustomCallback < Carnivore::Callback

  self.workers = 5

  def setup
    info "Custom callback setup called!"
  end

  def execute(message)
    info "GOT MESSAGE: #{message[:message]} - source: #{message[:source]} - instance: #{self}"
  end
end

Carnivore.configure do
  s = Carnivore::Source.build(:type => :test, :args => {})
  s.add_callback(:printer, CustomCallback)
end.start!
```

## Info

* Repository: https://github.com/heavywater/carnivore