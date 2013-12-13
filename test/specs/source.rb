require 'minitest/autorun'
require 'carnivore/source'

describe 'Carnivore::Source' do
  describe 'Carnivore::Source::SourceContainer' do
    before do
      @src_ctn = Carnivore::Source::SourceContainer.new(:my_name, {:arg1 => true})
    end

    it 'should store name in `klass` attribute' do
      @src_ctn.klass.must_equal :my_name
    end

    it 'should store argument hash in `source_hash` attribute' do
      @src_ctn.source_hash.must_equal :arg1 => true, :callbacks => {}
    end

    describe 'callback additions' do
      before do
        @block = lambda{ 'hi' }
        @src_ctn.add_callback(:hi, &@block)
      end

      it 'should store callback by name in `source_hash` under `:callbacks`' do
        @src_ctn.source_hash.keys.must_include :callbacks
        @src_ctn.source_hash[:callbacks].keys.must_include :hi
        @src_ctn.source_hash[:callbacks].values.must_include @block
      end
    end
  end

  describe 'Custom source providers' do

    before do
      Carnivore::Source.provide(:meat_bag, 'carnivore-meat-bag/meat_bag')
    end

    it 'gives expected require path if registered' do
      Carnivore::Source.require_path(:meat_bag).must_equal 'carnivore-meat-bag/meat_bag'
    end

    it 'gives `nil` require path if not registered' do
      Carnivore::Source.require_path(:test).must_be_nil
    end
  end

  describe 'Source registration' do
    before do
      @inst = Object.new
      Carnivore::Source.register(:my_source, @inst)
    end

    it 'provides list of registered sources' do
      Carnivore::Source.sources.must_include @inst
    end

    it 'allows accessing registered source by name' do
      Carnivore::Source.source(:my_source).must_equal @inst
    end
  end

  describe 'Processing with base Source instance' do
    it 'should raise an exception' do
      -> {
        x = Carnivore::Source.new(:auto_process => false)
        x.add_callback(:fubar, lambda{|m| true })
        x.process
      }.must_raise NoMethodError
    end
  end

  describe 'Source test instance' do
    describe 'with no name argument' do
      before do
        require 'carnivore/source/test'
        @source = Carnivore::Source::Test.new
      end

      it 'should generate name if none provided' do
        @source.name.wont_be :empty?
      end
    end
  end
end
