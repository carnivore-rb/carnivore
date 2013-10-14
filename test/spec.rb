require 'celluloid'
Celluloid.logger.level = 4

Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'specs/*.rb')).each do |path|
  require path
end

MiniTest::Spec.before do
  Celluloid.shutdown
  Celluloid.boot
end
