require 'carnivore'

Carnivore.configure do
  s = Carnivore::Source.build(:type => :test, :args => {})

  s.add_callback(:printer) do |message|
    info "GOT MESSAGE: #{message[:message]} - source: #{message[:source]} - instance: #{self}"
  end

end.start!
