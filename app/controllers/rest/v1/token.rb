module Rest
  module V1
    class Token
      TTL = 30.days
      LIMIT_TOKENS_PER_ACCOUNT = 300

      def initialize(au_token = nil)
        @auth_token = au_token
      end

      def authenticate
        error = User.new.sign_in @auth_token[:email], @auth_token[:password]
        if error.blank?
          token = SecureRandom.uuid
          auth_token = $auth_tokens.detect { |au| au[:email] == @auth_token[:email] }
          if auth_token
            return { status: false, message: 'Over limit token per account. Please contact your administrator for helping.' } if auth_token[:tokens].size >= LIMIT_TOKENS_PER_ACCOUNT
            auth_token[:tokens] << { token: token, created_at: Time.zone.now }
          else
            $auth_tokens.push(
              email: @auth_token[:email],
              tokens: [
                token: token,
                created_at: Time.zone.now
              ])
          end

          Thread.new { clean_expire_token }
          { status: true, session: token }
        else
          { status: false, message: error }
        end
      end

      def expired?
        elapsed = Time.zone.now - @auth_token[:created_at]
        remaining = (TTL - elapsed).floor
        remaining <= 0
      end

      def clean_expire_token
        $auth_tokens.each { |auth_token| auth_token[:tokens].delete_if { |token| Token.new(token).expired? } }
        $auth_tokens.delete_if(&:blank?)
      rescue => e
        Rails.logger.error ModelCommon.full_exception_error(e)
      end
    end
  end
end
