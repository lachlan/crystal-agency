module Agency
  # Agent for executing a block
  class Task
    include Agent

    def initialize(*, @name : String? = nil, retry_policy : RetryPolicy? = nil, &@block)
      @retry_policy = retry_policy if retry_policy
    end

    def name : String
      @name || super
    end

    private def run : Nil
      @block.call
    end
  end
end
