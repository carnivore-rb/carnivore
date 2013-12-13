require 'carnivore/config'

describe 'Carnivore::Config' do
  describe 'Direct Configuration' do
    it 'allows direct configuration set' do
      Carnivore::Config[:direct] = true
      Carnivore::Config[:direct].must_equal true
    end

    it 'returns nil when configuration is undefined' do
      Carnivore::Config[:missing].must_be_nil
    end

    it 'raises exception when accessing nested keys that do not exist' do
      -> { Carnivore::Config[:missing][:key] }.must_raise NoMethodError
    end

  end

  describe '#get helper' do
    it 'returns the nested configuration value' do
      Carnivore::Config[:nested] = {:value => 'hello world'}
      Carnivore::Config.get(:nested, :value).must_equal 'hello world'
    end

    it 'returns `nil` when nested configuration does not exist' do
      Carnivore::Config.get(:value, :does, :not, :exist).must_be_nil
    end
  end
end
