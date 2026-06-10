class AdminPolicy < ApplicationPolicy
  def access?
    user.present? && user.admin?
  end

  def index?
    access?
  end
end
