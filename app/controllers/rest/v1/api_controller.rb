module Rest
  module V1
    class ApiController < ApplicationController
      skip_before_filter :verify_authenticity_token
      before_filter :authenticate_header, only: [:upload_outpost_json_file, :register, :add_email_queue, :update_outpost_running_count]

      def sso
        token = Token.new(email: params[:email], password: params[:password])
        render json: token.authenticate
      end

      def upload_outpost_json_file
        json_content = request.body.read

        return api_respond 'Body\'s json content is missing or empty' if json_content.blank?

        token = nil
        $auth_tokens.each do |a_t|
          has_token = a_t[:tokens].detect { |t| t[:token] == @session_token }
          if has_token
            token = a_t
            break
          end
        end unless $auth_tokens.blank?

        return api_respond 'Could not detect session' unless token

        user = User.find_by(email: token[:email])
        upload_result = Op::Utility.upload_file(json_content, user)
        api_respond upload_result[:message], upload_result[:status]
      end

      def register
        data = params[:api]
        response = Outpost.register data
        api_respond response[:message], response[:status]
      end

      def add_email_queue
        obj = EmailQueue.add_queue params[:run_id], params[:email_list]

        return api_respond 'Successfully created email queue!', true if obj.is_a? EmailQueue
        api_respond 'Error occurred when creating email queue!'
      end

      def update_outpost_running_count
        response = Outpost.update_running_count name: params[:name], running_count: params[:running_count]
        api_respond response[:message], response[:status]
      end

      private

      def authenticate_header
        @session_token = request.headers['HTTP_TC_SESSION_TOKEN']
        return api_respond 'Not Authorized' unless @session_token

        token = nil
        $auth_tokens.each do |a_t|
          token = a_t[:tokens].detect { |t| t[:token] == @session_token }
          break if token
        end unless $auth_tokens.blank?

        return api_respond unless token

        token_cls = Token.new token
        api_respond if token_cls.expired?
      end

      def api_respond(message = 'Token not exist or expired', status = false)
        render json: { status: status, message: message }
      end
    end
  end
end
