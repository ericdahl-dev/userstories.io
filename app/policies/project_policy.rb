class ProjectPolicy < ApplicationPolicy
  def index?   = true
  def show?    = owns?
  def create?  = user.present?
  def update?  = owns?
  def destroy? = owns?
  def rotate_token? = owns?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def owns?
    user.present? && record.user_id == user.id
  end
end
