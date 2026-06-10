require "rails_helper"

RSpec.describe AdminDashboardMetrics do
  include ActiveSupport::Testing::TimeHelpers

  subject(:metrics) { described_class.new(window: window) }

  let(:window) { "30d" }

  describe "#submission_counts" do
    it "returns counts grouped by status within the window" do
      travel_to Time.zone.parse("2026-06-15 12:00:00") do
        create(:submission, status: "pending", created_at: 2.days.ago)
        create(:submission, status: "accepted", created_at: 3.days.ago)
        create(:submission, status: "dismissed", created_at: 40.days.ago)

        expect(metrics.submission_counts).to eq(
          "pending" => 1,
          "accepted" => 1,
          "dismissed" => 0,
          "shipped" => 0
        )
      end
    end
  end

  describe "#acceptance_rate" do
    it "returns accepted divided by accepted plus dismissed" do
      create_list(:submission, 2, status: "accepted")
      create(:submission, status: "dismissed")

      expect(metrics.acceptance_rate).to eq(66.7)
      expect(metrics.acceptance_rate_formula).to eq("accepted ÷ (accepted + dismissed)")
    end

    it "returns nil when no triage decisions exist" do
      create(:submission, status: "pending")

      expect(metrics.acceptance_rate).to be_nil
    end
  end

  describe "#magic_link_stats" do
    it "counts sends and sign-ins in the window" do
      travel_to Time.zone.parse("2026-06-15 12:00:00") do
        collaborator = create(:collaborator)
        create(:magic_token, collaborator: collaborator, created_at: 1.day.ago, used_at: 1.day.ago)
        create(:magic_token, collaborator: collaborator, created_at: 40.days.ago, used_at: 40.days.ago)

        expect(metrics.magic_link_stats).to eq(sent: 1, sign_ins: 1)
      end
    end
  end

  describe "#stale_pending_submissions" do
    it "returns pending submissions older than the threshold" do
      travel_to Time.zone.parse("2026-06-15 12:00:00") do
        stale = create(:submission, status: "pending", created_at: 10.days.ago)
        create(:submission, status: "pending", created_at: 1.day.ago)

        expect(metrics.stale_pending_submissions).to eq([ stale ])
      end
    end
  end
end
