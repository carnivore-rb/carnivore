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
