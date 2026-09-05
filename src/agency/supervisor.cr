module Agency
  module Supervisor
    include Agent

    # List of agents managed by this supervisor
    @agents = Array(Agent).new
    # Wait group used to wait on each managed agent to complete
    @dependents = WaitGroup.new

    # Adds an agent for supervision
    def <<(agent : Agent) : self
      @mutex.synchronize do
        raise ArgumentError.new("#{name} already supervises #{agent.name}") if @agents.includes?(agent)
        @agents << agent
        start(agent) if started?
      end
      self
    end

    # Runs the given block immediately
    def task(*, name : String? = nil, retry_policy : RetryPolicy? = nil, &block) : Nil
      self << Task.new(name: name, retry_policy: retry_policy, &block)
    end

    # Runs the given block repeatedly at the specified interval
    def repeat(*, name : String? = nil, interval : Time::Span, retry_policy : RetryPolicy? = nil, &block) : Nil
      self << RepeatingTask.new(interval: interval, name: name, retry_policy: retry_policy, &block)
    end

    # Runs the given block at the specified time
    def schedule(*, name : String? = nil, time : Time | Time::Instant, retry_policy : RetryPolicy? = nil, &block) : Nil
      self << ScheduledTask.new(time: time, name: name, retry_policy: retry_policy, &block)
    end

    # Starts all managed agents
    private def startup : Nil
      @dependents = WaitGroup.new
      if agents = @agents
        agents.each do |agent|
          start(agent)
        end
      end
    end

    # Starts the given agent
    private def start(agent : Agent) : Nil
      @dependents.add(1)
      agent.spawn(notify: self)
      Fiber.yield # important: allow each new agent fiber to run
    rescue ex
      @dependents.done
    end

    # Can be overridden by implementing types if the supervisor also needs to
    # perform its own work
    private def run : Nil
      @dependents.wait
    end

    # Stops all managed agents
    private def shutdown : Nil
      @agents.reverse_each &.stop
    end

    # Handles when a supervised agent stops
    protected def notify(agent : Agent, exception : Exception? = nil) : Nil
      @dependents.done if @agents.includes?(agent)
    end

    # Waits for the agent to stop
    def await : Nil
      @dependents.wait
      super
    end

    # Returns the current health of the supervisor and its agents
    def health : Health?
      @mutex.synchronize do
        supervisor_health : Health? = nil
        supervisor_healthy = true
        dependents : Array(Health)? = nil
        unless @agents.empty?
          dependents = Array(Health).new
          @agents.each do |agent|
            begin
              if health = agent.health
                dependents << health
              end
            rescue ex
              results = Array(Health::Check).new
              results << Health::Check.new("Exception raised by health check: #{ex}", false)
              dependents << Health.new(agent.name, agent.description, results)
              Log.error(exception: ex) { "HEALTH #{agent.name}" }
            end
          end
          supervisor_health = Health.new(name, description, nil, dependents) unless dependents.empty?
        end
        return supervisor_health
      end
    end
  end
end
