# Agency

Crystal language shard which provides simple traits to be included for agents
that can start and stop, and supervisors which manage a list of agents.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     agency:
       github: lachlan/crystal-agency
   ```

2. Run `shards install`

## Usage

```crystal
require "agency"

class ExampleAgent
  include Agency::Agent

  def run : Nil
    count = 1
    while started?
      Log.info { "count = #{count}" }
      count += 1
      sleep 1.second
    end
  end
end

class ExampleSupervisor
  include Agency::Supervisor
end

agent = ExampleAgent.new
supervisor = ExampleSupervisor.new
supervisor << agent # supervise the agent with the supervisor
supervisor.start # starts self and all managed agents and waits for completion
```

## Contributing

1. Fork it (<https://github.com/lachlan/crystal-agency/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Lachlan Dowding](https://github.com/lachlan) - creator and maintainer
