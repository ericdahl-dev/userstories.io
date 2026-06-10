class AdminDashboardMetrics
  WINDOWS = %w[today 7d 30d all].freeze
  STALE_PENDING_DAYS = 7
  RECENT_SUBMISSIONS_LIMIT = 25

  def initialize(window: "30d")
    @window = WINDOWS.include?(window) ? window : "30d"
  end

  attr_reader :window

  def platform_totals
    {
      users: User.count,
      projects: Project.count,
      collaborators: Collaborator.count
    }
  end

  def submission_counts
    grouped = scoped_submissions.group(:status).count
    Submission::STATUSES.index_with { |status| grouped[status] || 0 }
  end

  def acceptance_rate
    accepted = submission_counts.fetch("accepted")
    dismissed = submission_counts.fetch("dismissed")
    decided = accepted + dismissed
    return if decided.zero?

    (accepted.to_f / decided * 100).round(1)
  end

  def acceptance_rate_formula
    "accepted ÷ (accepted + dismissed)"
  end

  def magic_link_stats
    scoped = scoped_magic_tokens
    {
      sent: scoped.count,
      sign_ins: scoped.where.not(used_at: nil).count
    }
  end

  def recent_submissions
    scoped_submissions.recent.includes(:project, :collaborator).limit(RECENT_SUBMISSIONS_LIMIT)
  end

  def stale_pending_submissions
    Submission.pending_review
              .where(submissions: { created_at: ...STALE_PENDING_DAYS.days.ago })
              .includes(:project, :collaborator)
              .recent
              .limit(RECENT_SUBMISSIONS_LIMIT)
  end

  def recent_job_failures
    GoodJob::Job.where.not(error: nil).order(created_at: :desc).limit(10)
  end

  private

  def scoped_submissions
    range = time_range
    range ? Submission.where(created_at: range) : Submission.all
  end

  def scoped_magic_tokens
    range = time_range
    range ? MagicToken.where(created_at: range) : MagicToken.all
  end

  def time_range
    case @window
    when "today" then Time.current.beginning_of_day..
    when "7d" then 7.days.ago..
    when "30d" then 30.days.ago..
    end
  end
end
