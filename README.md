# Carnivore

Eat messages, rule the world.

## Purpose

Slim library to consume messages. Sources are defined
and callbacks are registered to these sources. Worker pools
then apply the messages to the defined callbacks asynchronously.
Super simple!

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
end
```

## Info

* Repository: https://github.com/spox/carnivore