module Agency
  module Transformer(M, N)
    include Agent

    @producer : Producer(M)
    @consumer : Consumer(N)

    # Runs the transformer, receiving messages from the producer, transforming
    # each message, and sending the transformed messages to the consumer
    private def run : Nil
      while started?
        while started? && (producer = @producer) && (consumer = @consumer) && producer.started? && consumer.started? && (input = producer.receive)
          if output = transform(input)
            consumer.send(output)
          end
          Fiber.yield
        end
        Fiber.yield
      end
    rescue ex : Channel::ClosedError
      raise ex if @producer.started? && @consumer.started?
    end

    # Transforms the input message to an output message, or nil if the input
    # message is to be ignored, to be implemented by inheriting types
    private abstract def transform(input : M) : N?
  end
end
