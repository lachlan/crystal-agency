module Agency
  # Agent for repeating tasks on a set interval
  class RepeatingTask
    include Agent

    def initialize(*, @interval : Time::Span, @name : String? = nil, retry_policy : RetryPolicy? = nil, &@block)
      @retry_policy = retry_policy if retry_policy
    end

    def name : String
      @name || super
    end

    private def run : Nil
      while started?
        @block.call
        sleep(@interval)
      end
    end
  end
end
