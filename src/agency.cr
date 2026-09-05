require "log"
require "./agency/agent"
require "./agency/repeating_task"
require "./agency/scheduled_task"
require "./agency/task"
require "./agency/supervisor"
require "./agency/messenger"
require "./agency/consumer"
require "./agency/producer"
require "./agency/pipeline"
require "./agency/transformer"

# Provides a framework for agents, consumers, producers, and supervisors.
module Agency
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  Log     = ::Log.for("AGENCY")
end
