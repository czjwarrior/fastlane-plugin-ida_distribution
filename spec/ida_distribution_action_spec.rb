describe Fastlane::Actions::IdaDistributionAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The ida_distribution plugin is working!")

      Fastlane::Actions::IdaDistributionAction.run(nil)
    end
  end
end
