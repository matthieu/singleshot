module Spec
  module Rails
    module Matchers
      
      class PresentMatcher
        def initialize(presenter, format)
          @presenter = presenter
          @format = format
        end

        def matches?(response)
          @expect = response.body
          @actual = @presenter.send("to_#{@format.to_sym}")
          @actual == @expect
        end

        def failure_message
          "Expected #{@expect.inspect}, found #{@actual.inspect}"
        end

        def negative_failure_message
          "Found unexpected #{@actual.inspect}"
        end
      end
      
      include Presenter::PresentingMethod
      
      def present(*args)
        PresentMatcher.new(presenting(*args), request.format)
      end
    end
  end
end