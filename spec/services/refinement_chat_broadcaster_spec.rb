require "rails_helper"

RSpec.describe RefinementChatBroadcaster do
  let(:submission) { create(:submission) }
  let(:message) { create(:refinement_message, submission: submission, role: "assistant", body: "Refined draft") }

  subject(:broadcaster) { described_class.new(submission) }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_remove_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to)
  end

  it "broadcasts stream updates when an assistant reply completes" do
    broadcaster.complete_assistant_reply!(message)

    expect(Turbo::StreamsChannel).to have_received(:broadcast_remove_to)
      .with(submission, target: "refinement_typing_indicator")
    expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
      .with(submission, hash_including(target: "refinement_messages", partial: "portal/refinements/message"))
    expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to)
      .with(submission, hash_including(target: "refinement_composer"))
    expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to)
      .with(submission, hash_including(target: "refinement_reply_counter"))
  end

  it "broadcasts a failure state when processing fails" do
    broadcaster.processing_failed!

    expect(Turbo::StreamsChannel).to have_received(:broadcast_remove_to)
      .with(submission, target: "refinement_typing_indicator")
    expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
      .with(submission, hash_including(partial: "portal/refinements/failure_alert"))
    expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to)
      .with(submission, hash_including(target: "refinement_composer"))
  end
end
