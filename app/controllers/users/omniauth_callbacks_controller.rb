class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def github
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      is_new = @user.previously_new_record?

      PostHog.identify(
        distinct_id: @user.posthog_distinct_id,
        properties: @user.posthog_properties
      )
      PostHog.capture(
        distinct_id: @user.posthog_distinct_id,
        event: is_new ? "developer_signed_up" : "developer_signed_in",
        properties: { login_method: "github" }
      )

      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "GitHub") if is_navigational_format?
    else
      session["devise.github_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: "GitHub authentication failed."
  end
end
