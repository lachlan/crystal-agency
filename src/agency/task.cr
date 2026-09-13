module Agency
  # Agent for executing a block
  class Task
    include Agent

    def initialize(*, @name : String? = nil, retry_policy : RetryPolicy? = nil, &@block)
      @retry_policy = retry_policy if retry_policy
    end

    def name : String
      super + "#{@name.nil? ? "" : " (" + @name.to_s + ")"}"
    end

    private def run : Nil
      @block.call
    end
  end

  # Agent for repeating tasks on a set interval
  class RepeatingTask < Task
    def initialize(*, @interval : Time::Span, @name : String? = nil, retry_policy : RetryPolicy? = nil, &@block)
      @retry_policy = retry_policy if retry_policy
    end

    private def run : Nil
      while started?
        begin
          @block.call
        rescue ex
          raise ex
        else
          @retry_policy.reset # if task succeeds then restart retry count
        end
        sleep(@interval)
      end
    end
  end

  # Agent for executing a task at a specific time
  class ScheduledTask < Task
    def initialize(*, @time : Time | Time::Instant, @name : String? = nil, retry_policy : RetryPolicy? = nil, &@block)
      @retry_policy = retry_policy if retry_policy
    end

    private def run : Nil
      sleep_until @time
      @block.call if started?
    end
  end
end
