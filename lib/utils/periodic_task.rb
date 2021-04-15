module AsyncCable
  module Utils
    class PeriodicTask < Task
      def initialize(every:, &block)
        super() do |task|
          while true
            block.call(task)
            task.sleep(every)
          end
        end
      end
    end
  end
end