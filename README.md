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
    puts "Received message: #{msg}"
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

### Block execution

It is important to note that when providing blocks, they will
lose all reference to the scope in which they are defined. This
is due to how `Callback` is implemented and is by design. Simply
ensure that blocks are fully autonomous and everything will be
great.

#### Example (bad):

```ruby
Carnivore.configure do
  my_inst = AwesomeSauce.new
  src = Source.build(:type => :test, :args => {})
  src.add_callback(:print_message) do |msg|
    my_inst.be_awesome!
    puts "Received message: #{msg}"
  end
end.start!
```

#### Example (good):

```ruby
Carnivore.configure do
  src = Source.build(:type => :test, :args => {})
  src.add_callback(:print_message) do |msg|
    my_inst = AwesomeSauce.new
    my_inst.be_awesome!
    puts "Received message: #{msg}"
  end
end.start!
```

So, does that mean a new `AwesomeSauce` instance will be
created on every message processed? Yes, yes it does. However,
the block at runtime is no longer really a block, so lets
keep that instance around so it can be reused:

#### Example (more gooder):

```ruby
Carnivore.configure do
  src = Source.build(:type => :test, :args => {})
  src.add_callback(:print_message) do |msg|
    unless(@my_inst)
      @my_inst = AwesomeSauce.new
    end
    @my_inst.be_awesome!
    puts "Received message: #{msg}"
  end
end.start!
```

## Info

* Repository: https://github.com/carnivore-rb/carnivore
* IRC: Freenode @ #carnivore