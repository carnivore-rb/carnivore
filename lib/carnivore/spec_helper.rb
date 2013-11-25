require 'celluloid'
Celluloid.logger.level = 4

if(File.directory?(dir = File.join(Dir.pwd, 'test', 'specs')))
  Dir.glob(File.join(dir, '*.rb')).each do |path|
    require path
  end
else
  puts 'Failed to locate `test/specs` directory. Are you in project root directory?'
  exit -1
end

MiniTest::Spec.before do
  Celluloid.shutdown
  Celluloid.boot
end

def source_wait
  sleep(0.1)
end


# dummy store that should never be used for anything real
class MessageStore
  class << self

    def init
      @messages = []
    end

    def messages
      @messages
    end

  end
end
