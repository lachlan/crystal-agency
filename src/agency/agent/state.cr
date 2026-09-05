module Agency
  module State
    enum Status
      STARTED # started and allowed to stop or fail
      STOPPED # stopped and allowed to start
    end

    @status : Atomic(Status) = Atomic.new(Status::STOPPED)
    @status_change_channel = Channel(Status).new
    @mutex : Mutex = Mutex.new(Mutex::Protection::Reentrant)

    # Sets the current status of the agent
    private def set_status(new_status : Status) : Nil
      @mutex.synchronize do
        old_status = @status.get
        raise ArgumentError.new("BUG: #{name} attempted illegal status transition: #{old_status} --> #{new_status}") unless is_valid_status_transition?(old_status, new_status)
        loop do
          _, success = @status.compare_and_set(old_status, new_status, :acquire_release, :acquire)
          if success
            Log.debug { "#{new_status} #{name}" }
            # signal status change to any sleepers by closing the channel
            @status_change_channel.try &.close
            @status_change_channel = Channel(Status).new
            break
          end
        end
      end
    end

    # Returns true if the given status transition is considered valid
    private def is_valid_status_transition?(old_status : Status, new_status : Status) : Bool
      case old_status
      in Status::STARTED
        new_status == Status::STOPPED
      in Status::STOPPED
        new_status == Status::STARTED
      end
    end

    # Returns the current status of the agent
    def status : Status
      @status.get
    end

    # Returns true if the agent is started
    def started? : Bool
      @status.get == Status::STARTED
    end

    # Returns true if the agent is stopped
    def stopped? : Bool
      @status.get == Status::STOPPED
    end

    # Sleeps for the given interval or until the status changes, whichever
    # comes first
    private def sleep(interval : Time::Span = 1.second) : Nil
      raise "interval must not be negative: #{interval}" if interval.negative?
      if channel = @status_change_channel
        select
        when channel.receive?
          # status changed so we stop sleeping immediately
        when timeout(interval)
          # sleep for the given interval
        end
      end
    end

    # Sleeps until the given time or until the status changes, whichever comes
    # first
    private def sleep_until(time : Time) : Nil
      sleep((time.to_unix_f - Time.local.to_unix_f).clamp(0..).seconds)
    end

    # Sleeps until the given time or until the status changes, whichever comes
    # first
    private def sleep_until(time : Time::Instant) : Nil
      sleep((time - Time.instant).clamp(0.seconds..))
    end
  end
end
