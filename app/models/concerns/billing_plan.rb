# frozen_string_literal: true

module BillingPlan
  extend ActiveSupport::Concern

  PLANS = %w[free pro].freeze
  FREE_REFINEMENTS_PER_MONTH = 10
  PRO_REFINEMENTS_PER_MONTH = 200
  FREE_PROJECT_LIMIT = 1
  FREE_MODEL = "openai/gpt-4o-mini"

  included do
    validates :plan, inclusion: { in: PLANS }
  end

  def pro?
    plan == "pro"
  end

  def free?
    !pro?
  end

  def refinement_quota
    pro? ? PRO_REFINEMENTS_PER_MONTH : FREE_REFINEMENTS_PER_MONTH
  end

  def refinement_quota_remaining
    reset_refinement_usage_if_needed!
    [ refinement_quota - refinement_usage_count, 0 ].max
  end

  def refinement_quota_exhausted?
    refinement_quota_remaining.zero?
  end

  def can_create_project?
    return true if pro?
    return true if grandfathered_projects?

    projects.count < FREE_PROJECT_LIMIT
  end

  def consume_refinement_session!
    reset_refinement_usage_if_needed!
    increment!(:refinement_usage_count)
  end

  def reset_refinement_usage_if_needed!
    current_period = Date.current.beginning_of_month

    if refinement_usage_period_start.nil?
      update!(refinement_usage_period_start: current_period)
    elsif refinement_usage_period_start < current_period
      update!(refinement_usage_count: 0, refinement_usage_period_start: current_period)
    end
  end
end
