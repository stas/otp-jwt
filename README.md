# OTP JWT ⎆

One time password (email, SMS) authentication support for HTTP APIs.

> The man who wrote the book on password management has a confession to make:
> He blew it.
>
>— [WSJ.com](https://www.wsj.com/articles/the-man-who-wrote-those-password-rules-has-a-new-tip-n3v-r-m1-d-1502124118)

This project provides a couple of mixins to help you build
applications/HTTP APIs without asking your users to provide passwords.

[Your browser probably can work seamlessly with OTPs](https://web.dev/web-otp/)!!! :heart_eyes: 

## About

The goal of this project is to provide support for one time passwords
which are delivered via different channels (email, SMS), along with a
simple and easy to use JWT authentication.

Main goals:
 * No _magic_ please
 * No DSLs please
 * Less code, less maintenance
 * Good docs and test coverage
 * Keep it up-to-date (or at least tell people this is no longer maintained)

The available features include:
 * Flexible models support for
   [counter based OTP](https://github.com/mdp/rotp#counter-based-otps)
 * Flexible JWT token generation helpers for models and arbitrary data
 * Pluggable authentication flow using the OTP and JWT
 * Pluggable OTP mailer
 * Pluggable OTP SMS background processing job


This little project wouldn't be possible without the previous work on
[ROTP](https://github.com/mdp/rotp)
and [JWT](https://github.com/jwt/ruby-jwt/).

Thanks to everyone who worked on these amazing projects!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'otp-jwt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install otp-jwt

## Usage

 * [OTP for Active Record models](#otp-for-active-record-models)
   * [Mailer support](#mailer-support)
   * [SMS delivery support](#sms-delivery-support)
 * [JWT for Active Record models](#jwt-for-active-record-models)
 * [JWT authorization](#jwt-authorization)
 * [JWT authentication](#jwt-authentication)
 * [JWT Tokens](#jwt-tokens)

---

To start using it with Rails, add this to an initializer and configure your
keys:

```ruby
# config/initializers/otp-jwt.rb
require 'otp'
# To load the JWT related support.
require 'otp/jwt'

OTP::JWT::Token.jwt_signature_key = ENV['YOUR-SIGN-KEY']
```
### OTP for Active Record models

To add support for OTP to your models, use the `OTP::ActiveRecord` concern:

```ruby
class User < ActiveRecord::Base
  include OTP::ActiveRecord

  ...
end
```

This will provide two new methods which you can use to generate and verify
one time passwords:
 * `User#otp`
 * `User#verify_otp`

This concern expects two attributes to be provided by the model, the:
 * `otp_secret`: of type string, used to store the OTP signature key
 * `otp_counter`: of type integer, used to store the OTP counter

A migration to add these two looks like this:
```
$ rails g migration add_otp_to_users otp_secret:string otp_counter:integer
```

Generate `opt_secret` by running the following in rails console if you have preexisting user data:
```
User.all.each do |u|
  u.save()
end
```
#### Mailer support

You can use the built-in mailer to deliver the OTP, just require it and
overwrite the helper method:

```ruby
require 'otp/mailer'

class User < ActiveRecord::Base
  include OTP::ActiveRecord

  def email_otp
    OTP::Mailer.otp(email, otp, self).deliver_later
  end
end
```

To customize the mailer subject, address and template, update the defaults:

```ruby
require 'otp/mailer'

OTP::Mailer.default subject: 'Your App magic password 🗝️'
OTP::Mailer.default from: ENV['DEFAUL_MAILER_FROM']
# Tell mailer to use the template from app/views/otp/mailer/otp.html.erb
OTP::Mailer.prepend_view_path(Rails.root.join('app', 'views'))
```

#### SMS delivery support

You can use the built-in job to deliver the OTP via SMS, just require it and
overwrite the helper method:

```ruby
require 'otp/sms_otp_job'

class User < ActiveRecord::Base
  include OTP::ActiveRecord

  SMS_TEMPLATE = '%{otp} is your APP magic password 🗝️'

  def sms_otp
    OTP::SMSOTPJob.perform_later(
      phone_number,
      otp,
      SMS_TEMPLATE # <-- Optional text message template.
    ) if phone_number.present?
  end
end
```

You will have to provide your model with the phone number attribute if you
want to deliver the OTPs via SMS.

This job requires `aws-sdk-sns` gem to work. You will have to add it manually
and configure to use the correct keys. The SNS region is fetched from the
environment variable `AWS_SMS_REGION`.

### JWT for Active Record models

To add support for JWT to your models, use the `OTP::JWT::ActiveRecord` concern:

```ruby
class User < ActiveRecord::Base
  include OTP::JWT::ActiveRecord

  ...
end
```

This will provide two new methods which you can use to generate and verify JWT
tokens:
 * `User#from_jwt`
 * `User#to_jwt`

### JWT authorization

To add support for JWT to your controllers,
use the `OTP::JWT::ActionController` concern:

```ruby
class ApplicationController < ActionController::Base
  include OTP::JWT::ActionController

  private

  def current_user
    @jwt_user ||= User.from_jwt(request_authorization_header)
  end

  def current_user!
    current_user || raise('User authentication failed')
  rescue
    head(:unauthorized)
  end
end
```

The example from above includes helpers you can use interact with the
currently authenticated user or just use as part of `before_action` callback.

The `request_authorization_header` method is also provided by the concern and
allows you to customize from where the token is received. A query parameter
based alternative would look like this:

```ruby
class ApplicationController < ActionController::Base
  include OTP::JWT::ActionController

  private

  def current_user
    @jwt_user ||= User.from_jwt(params[:token])
  end

  ...
end
```

### JWT authentication

The `OTP::JWT::ActionController` concern provides support for handling the
authentication requests and token generation by using the `jwt_from_otp` method.

Here's an example of a tokens controller:

```ruby
class TokensController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    jwt_from_otp(user, params[:otp]) do |auth_user|
      # Let's update the last login date before we send the token...
      # auth_user.update_column(:last_login_at, DateTime.current)

      render json: { token: auth_user.to_jwt }, status: :created
    end
  end
end
```

The `jwt_from_otp` does a couple of things here:
 * It will try to authenticate the user you found by email and respond with
   a valid JWT token
 * It will try to schedule an email or SMS delivery of the OTP and it will
   respond with the 400 HTTP status
 * It will respond with the 403 HTTP status if there's no user
   or the OTP is wrong

The OTP delivery is handled by the `User#deliver_otp` method
and can be customized. By default it will call the `sms_otp` method and
if nothing is returned, it will proceed with the `email_otp` method.

### JWT Tokens

To help sign any sort of data, a lightweight JWT Token wrapper is provided.

Signing a payload will follow the pre-defined settings like the lifetime and
the encryption key. Decoding a token will validate any claims as well. Finally
there's a safe wrapper to help you with the JWT specific exceptions handling.

```ruby
require 'otp/jwt/token'

token = OTP::JWT::Token.sign(sub: 'my subject')
OTP::JWT::Token.decode(token) == {'sub' => 'my subject'}
OTP::JWT::Token.decode('bad token') == nil
```

## Development

After checking out the repo, run `bundle` to install dependencies.

Then, run `rake` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/stas/otp-jwt

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

TBD
