require 'carnivore/message'

describe 'Carnivore::Message' do

  it 'requires a Source to be provided' do
    -> { Carnivore::Message.new(:message => 'hi') }.must_raise ArgumentError
  end

  it 'provides argument access via `[]`' do
    message = Carnivore::Message.new(:source => true, :message => 'hi')
    message[:source].must_equal true
    message[:message].must_equal 'hi'
  end

  it 'provides direct argument hash access via `args`' do
    message = Carnivore::Message.new(:source => true, :message => 'hi')
    message.args.must_be_kind_of Hash
  end

  it 'provides `confirm!` confirmation helper to Source' do
    source = MiniTest::Mock.new
    # Mock items for hashie inspection on hash dup
    2.times do
      source.expect(:is_a?, false, [Object])
    end
    message = Carnivore::Message.new(:source => source, :message => 'hi')
    source.expect(:confirm, true, [message])
    message.confirm!
    source.verify
  end

end
