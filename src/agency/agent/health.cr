require "json"

module Agency
  module Health
    # Report on the health or otherwise of a component
    struct Health
      include JSON::Serializable

      # Individual health check result for a component
      struct Check
        include JSON::Serializable

        # Describes the specific health check
        getter description : String
        # Whether the specific health check passed (true) or failed (false)
        getter? healthy : Bool

        def initialize(@description : String, @healthy : Bool)
        end
      end

      # The name of the component whose health was checked
      getter component : String
      # Optional description of the component
      getter description : String?
      # The time the health report was generated
      getter datetime : Time = Time.local
      # Whether the component is healthy (true) or unhealthy (false)
      getter? healthy : Bool
      # The list of health checks undertaken to determine component health
      getter results : Array(Check)?
      # The list of dependent components whose health was checked to determine
      # the health of this component
      getter dependents : Array(Health)?

      def initialize(@component : String, @description : String? = nil, @results : Array(Check)? = nil, @dependents : Array(Health)? = nil)
        @healthy = calculate_health
      end

      # Is this component healthy?
      protected def calculate_health : Bool
        healthy = true
        if healthy && (results = @results)
          results.each do |result|
            healthy = healthy && result.healthy?
          end
        end
        if healthy && (dependents = @dependents)
          dependents.each do |dependent|
            healthy = healthy && dependent.healthy?
          end
        end
        healthy
      end

      # Is this component unhealthy?
      def unhealthy? : Bool
        !healthy?
      end

      # Filters the health results to only include unhealthy checks or
      # dependents
      def unhealthy : Health?
        health : Health? = nil
        filtered_results : Array(Check)? = nil
        filtered_dependents : Array(Health)? = nil
        if unhealthy?
          if results = @results
            filtered_results = results.reject { |r| r.healthy? }
            filtered_results = nil if filtered_results.empty?
          end
          if dependents = @dependents
            filtered_dependents = dependents.reject { |d| d.healthy? }.map { |d| d.unhealthy }.compact
            filtered_dependents = nil if filtered_dependents.empty?
          end
          health = Health.new(@component, @description, filtered_results, filtered_dependents)
        end
        health
      end
    end

    # Returns the current health of the agent, defaults to nil if not
    # implemented, to be overriden by inheriting types
    def health : Health?
      return nil
    end
  end
end
