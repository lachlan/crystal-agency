require "../agency"

{% if flag?(:win32) %}
  # Improve console logging performance on Windows
  STDOUT.sync = false
{% end %}

Log.setup(:debug)

class ExampleConsumer
  include Agency::Consumer(String)

  private def consume(message : String) : Nil
    raise "crash" if Random.rand(1..100) == 1
    Log.debug { "#{name} consumed message: #{message.inspect}" }
  end
end

class ExampleProducer
  include Agency::Producer(Int64)

  getter counter : Int64 = 0

  private def produce : Int64?
    sleep 1.second
    raise "crash" if Random.rand(1..100) == 1
    message = if started?
                @counter += 1
                @counter
              else
                nil
              end
    Log.debug { "#{name} produced message: #{message.inspect}" } if message
    message
  end

  private def teardown : Nil
    ::sleep 10.seconds
  end
end

class ExampleTransformer
  include Agency::Transformer(Int64, String)

  def initialize(@producer, @consumer)
  end

  private def transform(input : Int64) : String?
    raise "crash" if Random.rand(1..100) == 1
    output = input.to_s
    Log.debug { "#{name} transformed message: #{input.inspect} --> #{output.inspect}" }
    output
  end
end

class ExampleSupervisor
  include Agency::Supervisor

  def setup : Nil
    producer = ExampleProducer.new
    consumer = ExampleConsumer.new
    transformer = ExampleTransformer.new(producer, consumer)
    self << consumer << transformer << producer
  end

  def teardown : Nil
    @agents.clear
  end
end

supervisor = ExampleSupervisor.new

supervisor.repeat(name: "example repeating task", interval: 2.seconds, retry_policy: Agency::Agent::RetryPolicy.infinite(wait: 1.second..10.seconds, factor: 2.0)) do
  raise "crash" if Random.rand(1..2) == 1
  Log.info { "inside example repeating task" }
end

supervisor.schedule(name: "example scheduled task", time: Time.instant + 5.seconds) do
  Log.info { "inside example scheduled task" }
end

supervisor.task(name: "example task") do
  Log.info { "inside example task" }
end

Agency.run(supervisor)
