# frozen_string_literal: true

require "rails_helper"

RSpec.describe BillingPlan do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  describe "#can_create_project?" do
    it "allows a free developer to create their first project" do
      expect(user.can_create_project?).to be(true)
    end

    it "blocks a free developer from creating a second project" do
      create(:project, user: user)

      expect(user.can_create_project?).to be(false)
    end

    it "allows grandfathered free developers with multiple existing projects" do
      create_list(:project, 2, user: user)
      user.update!(grandfathered_projects: true)

      expect(user.can_create_project?).to be(true)
    end

    it "allows pro developers unlimited projects" do
      create_list(:project, 3, user: user)
      user.update!(plan: "pro")

      expect(user.can_create_project?).to be(true)
    end
  end

  describe "#reset_refinement_usage_if_needed!" do
    it "resets the counter when the billing period rolls over" do
      user.update!(
        refinement_usage_count: 8,
        refinement_usage_period_start: 1.month.ago.beginning_of_month.to_date,
        refinement_credit_balance: 5
      )

      travel_to Date.current.beginning_of_month + 2.days do
        user.reset_refinement_usage_if_needed!
        expect(user.reload).to have_attributes(
          refinement_usage_count: 0,
          refinement_usage_period_start: Date.current.beginning_of_month,
          refinement_credit_balance: 5
        )
      end
    end
  end

  describe "refinement credits" do
    it "includes bonus credits in remaining allowance" do
      user.update!(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_usage_period_start: Date.current.beginning_of_month,
        refinement_credit_balance: 3
      )

      expect(user.refinement_quota_remaining).to eq(3)
      expect(user.refinement_quota_exhausted?).to be(false)
    end

    it "consumes plan quota before bonus credits" do
      user.update!(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH - 1,
        refinement_usage_period_start: Date.current.beginning_of_month,
        refinement_credit_balance: 2
      )

      user.consume_refinement_session!

      expect(user.reload).to have_attributes(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_credit_balance: 2
      )
    end

    it "consumes bonus credits when plan quota is exhausted" do
      user.update!(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_usage_period_start: Date.current.beginning_of_month,
        refinement_credit_balance: 2
      )

      user.consume_refinement_session!

      expect(user.reload).to have_attributes(
        refinement_usage_count: BillingPlan::FREE_REFINEMENTS_PER_MONTH,
        refinement_credit_balance: 1
      )
    end
  end
end
