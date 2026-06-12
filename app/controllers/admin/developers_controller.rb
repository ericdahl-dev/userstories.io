# frozen_string_literal: true

module Admin
  class DevelopersController < BaseController
    before_action :set_developer, only: %i[show grant_credits]

    def index
      authorize :admin, :access?

      @query = params[:q].to_s.strip
      @developers = User.order(:email)
      if @query.present?
        @developers = @developers.where("email ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%")
      end
      @developers = @developers.limit(50)
    end

    def show
      authorize :admin, :access?

      @recent_grants = @developer.admin_credit_grants.includes(:granted_by).order(created_at: :desc).limit(20)
    end

    def grant_credits
      authorize :admin, :grant_credits?

      granter = AdminCreditGranter.new(recipient: @developer, granted_by: current_user)
      granter.grant!(amount: params[:amount], reason: params[:reason])

      redirect_to admin_developer_path(@developer),
                  notice: "Granted #{params[:amount].to_i} refinement credits to #{@developer.email}."
    rescue AdminCreditGranter::Error, ArgumentError => e
      redirect_to admin_developer_path(@developer), alert: e.message
    end

    private

    def set_developer
      @developer = User.find(params[:id])
    end
  end
end
