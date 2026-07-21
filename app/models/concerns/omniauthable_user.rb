module OmniauthableUser
  extend ActiveSupport::Concern

  class_methods do
    # Sign in via an OmniAuth provider. If the provider identity is already
    # known, return it; if an account with the same email exists (signed up with
    # a password), link the provider to it; otherwise create a confirmed account.
    def from_omniauth(auth)
      existing = find_by(provider: auth.provider, uid: auth.uid)
      return existing if existing

      user = find_by(email: auth.info.email)
      if user
        user.update(provider: auth.provider, uid: auth.uid)
        return user
      end

      create! do |u|
        u.provider = auth.provider
        u.uid = auth.uid
        u.email = auth.info.email
        u.password = Devise.friendly_token[0, 20]
        u.first_name = auth.info.first_name
        u.last_name = auth.info.last_name
        u.skip_confirmation!
      end
    end
  end
end
