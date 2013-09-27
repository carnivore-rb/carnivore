module Carnivore
  class Supervisor < Celluloid::SupervisionGroup

    Source.sources.each do |source|
      supervise(
        source.klass,
        as: source.source_hash[:name],
        args: [source.source_hash]
      )
    end

  end
end
