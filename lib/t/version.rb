module T
  class Version
    MAJOR = 2
    MINOR = 9
    PATCH = 0
    PRE = nil

    class << self
      # @return [String]
      def to_s
        [MAJOR, MINOR, PATCH, PRE].compact.join('.')
      end
    end
  end
end
