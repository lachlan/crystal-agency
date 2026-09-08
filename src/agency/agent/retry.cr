module Agency
  module Retry
    @retry_policy : RetryPolicy = RetryPolicy.infinite

    private def retry(*, policy : RetryPolicy? = nil, &) : Nil
      policy = @retry_policy if policy.nil?
      loop do
        yield
      rescue ex
        should_retry, retry_count, retry_limit, retry_wait = policy.should_retry?
        if should_retry && retry_wait
          Log.error(exception: ex) { "CRASHED #{name.to_s}, retrying (#{retry_count}/#{retry_limit.nil? ? "∞" : retry_limit}) #{retry_wait.zero? ? "immediately" : "in " + retry_wait.to_s}" }
          sleep retry_wait
        else
          suffix = " as all retries (#{retry_limit}/#{retry_limit}) have been exhausted" if retry_limit && retry_limit > 0
          Log.error(exception: ex) { "CRASHED #{name.to_s}, not retrying#{suffix.to_s}" }
          raise ex
        end
      else
        break
      end
    end

    struct RetryPolicy
      def initialize(@retry_limit : UInt64? = nil, @retry_wait : Range(Time::Span, Time::Span) = (0.seconds..0.seconds), @retry_factor : Float64 = 1_f64)
        @retry_count = 0_u64
      end

      def should_retry? : {Bool, UInt64, UInt64?, Time::Span?}
        @retry_count += 1
        retry = @retry_limit.nil? || @retry_count <= @retry_limit.not_nil!
        if retry
          wait = (@retry_wait.begin * (@retry_factor ** (@retry_count - 1))).clamp(@retry_wait)
        else
          wait = @retry_wait.begin
        end

        {retry, @retry_count, @retry_limit, wait}
      end

      def reset : Nil
        @retry_count = 0_u64
      end

      def self.none : RetryPolicy
        RetryPolicy.new(0_u64)
      end

      def self.finite(*, limit : UInt64) : RetryPolicy
        RetryPolicy.new(limit)
      end

      def self.finite(*, limit : UInt64, wait : Time::Span) : RetryPolicy
        self.finite(limit: limit, wait: wait..wait)
      end

      def self.finite(*, limit : UInt64, wait : Range(Time::Span, Time::Span)) : RetryPolicy
        RetryPolicy.new(limit, wait)
      end

      def self.finite(*, limit : UInt64, wait : Range(Time::Span, Time::Span), factor : Float64) : RetryPolicy
        RetryPolicy.new(limit, wait, factor)
      end

      def self.infinite : RetryPolicy
        RetryPolicy.new
      end

      def self.infinite(*, wait : Time::Span) : RetryPolicy
        self.infinite(wait: wait..wait)
      end

      def self.infinite(*, wait : Range(Time::Span, Time::Span)) : RetryPolicy
        RetryPolicy.new(nil, wait, 1_f64)
      end

      def self.infinite(*, wait : Range(Time::Span, Time::Span), factor : Float64) : RetryPolicy
        RetryPolicy.new(nil, wait, factor)
      end
    end
  end
end
