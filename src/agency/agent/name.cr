module Agency
  module Name
    # The name of the agent, to be overriden
    def name : String
      to_s
    end

    # The description of the agent, to be overriden
    def description : String?
      nil
    end
  end
end
