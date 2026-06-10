# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminCreditGranter do
  let(:admin) { create(:user, email: "ops@example.com") }
  let(:developer) { create(:user, email: "dev@example.com") }

  describe "#grant!" do
    it "adds credits and records the grant" do
      described_class.new(recipient: developer, granted_by: admin).grant!(
        amount: 5,
        reason: "Early adopter"
      )

      developer.reload
      expect(developer.refinement_credit_balance).to eq(5)
      expect(developer.admin_credit_grants.last).to have_attributes(
        amount: 5,
        reason: "Early adopter",
        granted_by: admin
      )
    end

    it "rejects non-positive amounts" do
      expect {
        described_class.new(recipient: developer, granted_by: admin).grant!(amount: 0)
      }.to raise_error(AdminCreditGranter::Error, "Amount must be at least 1")
    end
  end
end
