require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class IdaDistributionHelper
      # class methods that you define here become available in your action
      # as `Helper::IdaDistributionHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the ida_distribution plugin helper!")
      end
    end
  end
end
