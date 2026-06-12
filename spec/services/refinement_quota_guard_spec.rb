# frozen_string_literal: true

require "rails_helper"

RSpec.describe RefinementQuotaGuard do
  include ActiveSupport::Testing::TimeHelpers

  let(:developer) { create(:user) }
  let(:project) { create(:project, user: developer) }
  let(:submission) { create(:submission, project: project) }

  describe ".allowed?" do
    it "allows refinement when developer has quota remaining" do
      expect(described_class.allowed?(submission)).to be(true)
    end

    it "blocks refinement when free developer quota is exhausted" do
      developer.update!(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_usage_period_start: Date.current.beginning_of_month
      )

      expect(described_class.allowed?(submission)).to be(false)
    end

    it "allows refinement when plan quota is exhausted but bonus credits remain" do
      developer.update!(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_usage_period_start: Date.current.beginning_of_month,
        refinement_credit_balance: 2
      )

      expect(described_class.allowed?(submission)).to be(true)
    end

    it "allows follow-up turns during an active session even when quota is exhausted" do
      developer.update!(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_usage_period_start: Date.current.beginning_of_month
      )
      create(:refinement_message, submission: submission, role: "assistant", body: "Initial")

      expect(described_class.allowed?(submission)).to be(true)
    end

    it "resets usage at the start of a new month" do
      developer.update!(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_usage_period_start: 1.month.ago.beginning_of_month.to_date
      )

      travel_to Date.current.beginning_of_month + 1.day do
        expect(described_class.allowed?(submission)).to be(true)
        expect(developer.reload.refinement_usage_count).to eq(0)
      end
    end
  end

  describe ".consume_session!" do
    it "increments developer usage once for the first assistant message" do
      create(:refinement_message, submission: submission, role: "assistant", body: "Initial")

      expect {
        described_class.consume_session!(submission)
      }.to change { developer.reload.refinement_usage_count }.by(1)
    end

    it "consumes bonus credits when plan quota is already exhausted" do
      developer.update!(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_usage_period_start: Date.current.beginning_of_month,
        refinement_credit_balance: 2
      )
      create(:refinement_message, submission: submission, role: "assistant", body: "Initial")

      expect {
        described_class.consume_session!(submission)
      }.to change { developer.reload.refinement_credit_balance }.by(-1)
    end

    it "does not increment for follow-up assistant messages" do
      create(:refinement_message, submission: submission, role: "assistant", body: "Initial")
      described_class.consume_session!(submission)
      create(:refinement_message, submission: submission, role: "assistant", body: "Follow-up")

      expect {
        described_class.consume_session!(submission)
      }.not_to change { developer.reload.refinement_usage_count }
    end
  end
end
