require 'carnivore/supervisor'

describe 'Carnivore::Supervisor' do

  describe 'Building the supervisor' do

    before do
      @supervisor = Carnivore::Supervisor.build!
    end

    after do
      Carnivore::Supervisor.terminate!
    end

    it 'should populate the `supervisor`' do
      klass = Carnivore::Supervisor.supervisor.class
      klass.must_equal Carnivore::Supervisor
    end

    it 'should populate the `registry`' do
      klass = Carnivore::Supervisor.registry.class
      klass.must_equal Celluloid::Registry
    end

    it 'should return the `Carnivore::Supervisor` instance' do
      (@supervisor == nil).wont_equal true
      (@supervisor == Carnivore::Supervisor.supervisor).must_equal true
    end

  end

  describe 'Creating supervisors' do

    it 'should return a registry and supervisor pair' do
      result = Carnivore::Supervisor.create!
      result.size.must_equal 2
      registry = result.first.class
      registry.must_equal Celluloid::Registry
      supervisor = result.last.class
      supervisor.must_equal Carnivore::Supervisor
    end

    it 'should not affect a currently built `supervisor`' do
      main_supervisor = Carnivore::Supervisor.build!
      new_registry, new_supervisor = Carnivore::Supervisor.create!
      (new_registry == Carnivore::Supervisor.registry).wont_equal true
      (new_supervisor == Carnivore::Supervisor.supervisor).wont_equal true
    end

  end

end
