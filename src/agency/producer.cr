module Agency
  module Producer(M)
    include Messenger(M)

    # Runs the message producer, produces messages and sends them to the
    # messages channel
    private def run : Nil
      while started? && (message = produce)
        send(message)
        Fiber.yield
      end
    rescue ex : Channel::ClosedError
      # indicates the producer has been stopped, ignore
    end

    # Produces a message, or nil when there are no more messages to be
    # produced, to be implemented by inheriting types
    private abstract def produce : M?
  end
end
