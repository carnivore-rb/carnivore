require 'carnivore/utils'

describe 'Carnivore::Utils' do
  describe 'Carnivore::Utils::Logging' do
    before do
      @obj = Object.new
      @obj.extend(Carnivore::Utils::Logging)
      Carnivore::Logger.level = 0
    end

    after do
      Carnivore::Logger.level = 4
    end

    it 'adds logging methods' do
      %w(debug info warn error).each do |key|
        @obj.must_respond_to(key)
      end
    end

    it 'includes object information in logging output' do
      out, err = capture_subprocess_io do
        @obj.info 'hello world'
      end
      err.must_match %r{I,\s*\[.*?\]\s*INFO\s*--\s*:\s*#{Regexp.escape(@obj.inspect)}:\s*hello world\n}
    end
  end

  describe 'Carnivore::Utils::Params' do
    before do
      @obj = Object.new
      @obj.extend(Carnivore::Utils::Params)
    end

    it 'adds `symbolize_hash` method' do
      @obj.must_respond_to :symbolize_hash
    end

    it 'converts hash keys to symbols' do
      h = {'string' => {'another' => {'OneHere' => 'more'}}}
      converted = @obj.symbolize_hash(h)
      converted.keys.first.must_equal :string
      converted[:string][:another].keys.first.must_equal :one_here
    end
  end
end
