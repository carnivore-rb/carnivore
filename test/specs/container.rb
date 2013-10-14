require 'minitest/autorun'
require 'carnivore/container'

describe 'Carnivore::Container' do
  it 'provides logging helpers' do
    c = Carnivore::Container.new
    Carnivore::Container.must_respond_to :log
    c.must_respond_to :log
    %w(debug info warn error).each do |key|
      c.must_respond_to key
    end
  end
end
