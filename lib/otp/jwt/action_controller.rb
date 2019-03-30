module OTP
  module JWT
    # [ActionController] concern.
    module ActionController
      private

      # Authenticates a model and responds with a [JWT] token
      #
      # @return [String] with authentication token and country shop ID.
      def jwt_from_otp(model, otp)
        # Send the OTP if the model is trying to authenticate.
        if model.present? && otp.blank?
          job = model.deliver_otp
          return render(json: { job_id: job.job_id }, status: :bad_request)
        elsif model.present? && otp.present? && !model.verify_otp(otp)
          return head(:forbidden)
        elsif model.blank?
          return head(:forbidden)
        end

        return yield(model) if block_given?

        render json: { token: model.to_jwt }, status: :created
      end

      # Extracts a token from the authorization header
      #
      # @return [String] the token present in the header or nothing.
      def request_authorization_header
        return if request.headers['Authorization'].blank?

        request.headers['Authorization'].split.last
      end
    end
  end
end
