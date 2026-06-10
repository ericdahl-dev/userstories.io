# frozen_string_literal: true

class AdminCreditGrant < ApplicationRecord
  belongs_to :user
  belongs_to :granted_by, class_name: "User"

  validates :amount, numericality: { only_integer: true, greater_than: 0 }
end
