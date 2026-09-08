require "log"
require "./agency/agent"
require "./agency/task"
require "./agency/supervisor"
require "./agency/messenger"
require "./agency/consumer"
require "./agency/producer"
require "./agency/pipeline"
require "./agency/transformer"

# Provides a framework for agents, consumers, producers, and supervisors.
module Agency
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  Log     = ::Log.for("AGENCY")

  # How long to wait by default before forcibly exiting the program when
  # stopping the service
  DEFAULT_SHUTDOWN_TIMEOUT = 5.seconds
  # How long to wait before forcibly exiting the program on service
  # shutdown
  @@shutdown_timeout = DEFAULT_SHUTDOWN_TIMEOUT
  # Count of how many times Process.on_terminate has been called
  @@process_on_terminate_count = Atomic(Int64).new(0)

  # Sets how long to wait for a graceful shutdown to complete before
  # stopping the service and forcibly exiting the process
  def self.shutdown_timeout=(shutdown_timeout : Time::Span)
    raise ArgumentError.new("shutdown_timeout must be greater than zero: #{shutdown_timeout}") unless shutdown_timeout > Time::Span.zero
    @@shutdown_timeout = shutdown_timeout
  end

  # Returns how long to wait before forcibly exiting the program on
  # service shutdown
  def self.shutdown_timeout : Time::Span
    @@shutdown_timeout
  end

  # Runs the given block as the application process
  def self.run(&block) : Nil
    run(Task.new(&block))
  end

  # Runs the given agent as the application process
  def self.run(agent : Agent) : Nil
    # terminate the supervisor in response to a process termination
    Process.on_terminate do |reason|
      shutdown(agent, reason: reason, immediately: @@process_on_terminate_count.add(1) > 0)
    end
    at_exit { Log.info { "STOPPED" } }
    Log.info { "STARTED" }
    agent.start
  rescue ex
    Log.error(exception: ex)
  ensure
    shutdown(agent)
  end

  # Stops the application and exits the process
  private def self.shutdown(agent : Agent, *, reason : Process::ExitReason? = nil, immediately : Bool = false) : Nil
    # exit process immediately if required
    Process.exit if immediately

    # wait on a dedicated thread for a graceful shutdown within configured
    # timeout period, otherwise forcibly exit the process
    Fiber::ExecutionContext::Isolated.new("AGENCY SHUTDOWN") do
      if shutdown_timeout = @@shutdown_timeout
        ::sleep shutdown_timeout
      end
      Process.exit
    end

    # perform a graceful shutdown of the agent and process
    Log.info { "SHUTDOWN INITIATED BY PROCESS TERMINATION, REASON = #{reason}" } if reason
    agent.stop
    ::exit
  rescue ex
    # exit process immediately if an exception was thrown
    Process.exit
  end
end
