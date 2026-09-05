module Agency
  module Messenger(M)
    include Agent

    @messages : Channel(M) = Channel(M).new

    private def setup : Nil
      @messages = Channel(M).new if @messages.closed?
    end

    private def teardown : Nil
      @messages.close
    end

    def send(message : M) : self
      @messages.send(message)
      self
    end

    def receive : M
      @messages.receive
    end

    def receive? : M?
      @messages.receive?
    end

    def closed? : Bool
      @messages.closed?
    end
  end
end
