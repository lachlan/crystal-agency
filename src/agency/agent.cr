require "wait_group"

require "./agent/health"
require "./agent/name"
require "./agent/retry"
require "./agent/state"

module Agency
  module Agent
    include Health
    include Name
    include State
    include Retry

    @executor : Fiber::ExecutionContext = Fiber::ExecutionContext.current
    @tasks : WaitGroup = WaitGroup.new

    # Called by start to setup the agent in its initial pristine state, can be
    # overriden by implementing types
    private def setup : Nil
    end

    # Called by stop to teardown the agent, can be overriden by implementing
    # types
    private def teardown : Nil
    end

    # Called by start just prior to running
    private def startup : Nil
    end

    # Called by stop just prior to stopping
    private def shutdown : Nil
    end

    # Called by start to run the agent, must be implemented by implementing
    # types
    private abstract def run : Nil

    # Called when the given agent stops expectedly or unexpectedly, can be
    # overriden by implementing types
    protected def notify(agent : Agent, exception : Exception? = nil) : Nil
    end

    # Starts the agent by spawning another fiber to call setup then set the
    # status to STARTED then call run
    def spawn(*, notify : Agent? = nil)
      @executor.spawn(name: name) do
        start(notify: notify)
      end
      Fiber.yield # important: allow freshly spawned fiber to now run
    end

    # Starts the agent by calling setup, then setting the status to STARTED,
    # then calling startup, and then calling run
    def start(*, notify : Agent? = nil)
      @tasks.add(1)
      retry do
        @mutex.synchronize do
          setup
        ensure
          set_status Status::STARTED
          startup
        end
        run
      ensure
        stop await: false
      end
    rescue ex
      notify.notify(self, ex) rescue nil if notify
    else
      notify.notify(self) rescue nil if notify
    ensure
      @tasks.done
    end

    # Stops the agent, waiting for its run loop to complete
    def stop : Nil
      stop await: true
    end

    # Stops the agent by calling shutdown, then setting the status to STOPPED,
    # then calling teardown, and then optionally waiting for the run loop to
    # complete
    private def stop(*, await : Bool) : Nil
      @mutex.synchronize do
        unless stopped?
          begin
            shutdown
          ensure
            set_status Status::STOPPED
            Fiber.yield if await # important: allow run fiber to exit
            teardown
          end
        end
      end
    rescue ex
      Log.error(exception: ex) { "SUPPRESSED #{name}" }
    ensure
      await if await
    end

    # Waits for the agent to stop
    def await : Nil
      @tasks.wait
    end
  end
end
