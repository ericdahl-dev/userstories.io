class SubmissionPolicy < ApplicationPolicy
  def index?   = developer_owns_project?
  def show?    = developer_owns_project?
  def accept?  = developer_owns_project? && record.status == "pending"
  def dismiss? = developer_owns_project? && record.status == "pending"
  def ship?    = developer_owns_project? && record.status == "accepted"

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:project).where(projects: { user_id: user.id })
    end
  end

  private

  def developer_owns_project?
    user.present? && record.project.user_id == user.id
  end
end
