module Agency
  # Agent for executing a task at a specific time
  class ScheduledTask
    include Agent

    def initialize(*, @time : Time | Time::Instant, @name : String? = nil, retry_policy : RetryPolicy? = nil, &@block)
      @retry_policy = retry_policy if retry_policy
    end

    def name : String
      @name || super
    end

    private def run : Nil
      sleep_until @time
      @block.call if started?
    end
  end
end
