module Agency
  module Pipeline(M)
    include Agent

    @producer : Producer(M)
    @consumer : Consumer(M)

    # Runs the pipeline, receiving messages from the producer and sending them
    # to the consumer
    private def run : Nil
      while started?
        while started? && (producer = @producer) && (consumer = @consumer) && producer.started? && consumer.started? && (message = producer.receive)
          consumer.send(message)
          Fiber.yield
        end
        Fiber.yield
      end
    rescue ex : Channel::ClosedError
      raise ex if @producer.started? && @consumer.started?
    end
  end
end
