module AsyncCable
  module Utils
    class Task
      def initialize(&block)
        @block = block
        @_task = nil
      end

      def start
        self._task = Async { |task| block.call(task) }
      end

      def stop
        _task&.stop
      end

      private
      
      attr_reader :block
      attr_accessor :_task
    end
  end
end