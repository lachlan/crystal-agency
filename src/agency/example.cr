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
end

producer = ExampleProducer.new
consumer = ExampleConsumer.new
transformer = ExampleTransformer.new(producer, consumer)
supervisor = ExampleSupervisor.new

supervisor << consumer << transformer << producer

supervisor.spawn

supervisor.repeat(interval: 2.seconds) do
  Log.info { "inside example repeating task" }
end

supervisor.schedule(time: Time.instant + 5.seconds) do
  Log.info { "inside example scheduled task" }
end

supervisor.task do
  Log.info { "inside example task" }
end

supervisor.task do
  count = 0
  loop do
    Log.info { count += 1 }
    ::sleep 1.second
    Fiber.yield if Random.rand(1..100) == 1
  end
  puts count
end

sleep 10.seconds

supervisor.stop timeout: 1.minute
