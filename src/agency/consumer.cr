module Agency
  module Consumer(M)
    include Messenger(M)

    # Runs the message consumer, receives messages and calls consume to
    # process them
    private def run : Nil
      while started? && (message = receive)
        consume(message)
        Fiber.yield
      end
    rescue ex : Channel::ClosedError
      # indicates the consumer has been stopped, ignore
    end

    # Consumes a message, to be implemented by inheriting types
    private abstract def consume(message : M) : Nil
  end
end
