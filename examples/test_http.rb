require 'carnivore'

Carnivore.configure do
  s = Carnivore::Source.build(:type => :http, :args => {:bind => '0.0.0.0', :port => 3000})

  s.add_callback(:printer) do |message|
    info "GOT MESSAGE: #{message[:message][:body]} - path: #{message[:message][:request].url} - method: #{message[:message][:request].method} - source: #{message[:source]} - instance: #{self}"
  end

end.start!
