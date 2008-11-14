module Authlogic
  module ORMAdapters
    module ActiveRecordAdapter
      module ActsAsAuthentic
        # = Config
        #
        # Allows you to set various configuration when calling acts_as_authentic. Pass your configuration like the following:
        #
        #   class User < ActiveRecord::Base
        #     acts_as_authentic :my_option => "my value"
        #   end
        #
        # === Class Methods
        #
        # * <tt>acts_as_authentic_config</tt> - returns a hash of the acts_as_authentic configuration, including the defaults
        #
        # === Options
        #
        # * <tt>session_class</tt> - default: "#{name}Session",
        #   This is the related session class. A lot of the configuration will be based off of the configuration values of this class.
        #   
        # * <tt>crypto_provider</tt> - default: Authlogic::CryptoProviders::Sha512,
        #   This is the class that provides your encryption. By default Authlogic provides its own crypto provider that uses Sha512 encrypton.
        #   
        # * <tt>login_field</tt> - default: :login, :username, or :email, depending on which column is present, if none are present defaults to :login
        #   The name of the field used for logging in. Only specify if you aren't using any of the defaults.
        #   
        # * <tt>login_field_type</tt> - default: options[:login_field] == :email ? :email : :login,
        #   Tells authlogic how to validation the field, what regex to use, etc. If the field name is email it will automatically use :email,
        #   otherwise it uses :login.
        #   
        # * <tt>login_field_regex</tt> - default: if :login_field_type is :email then typical email regex, otherwise typical login regex.
        #   This is used in validates_format_of for the :login_field.
        #   
        # * <tt>login_field_regex_failed_message</tt> - the message to use when the validates_format_of for the login field fails. This depends on if you are
        #   performing :email or :login regex.
        #   
        # * <tt>change_single_access_token_with_password</tt> - default: false,
        #   When a user changes their password do you want the single access token to change as well? That's what this configuration option is all about.
        #
        # * <tt>single_access_token_field</tt> - default: :single_access_token, :feed_token, or :feeds_token, depending on which column is present,
        #   This is the name of the field to login with single access, mainly used for private feed access. Only specify if the name of the field is different
        #   then the defaults. See the "Single Access" section in the README for more details on how single access works.
        #
        # * <tt>password_field</tt> - default: :password,
        #   This is the name of the field to set the password, *NOT* the field the encrypted password is stored. Defaults the what the configuration
        #   
        # * <tt>crypted_password_field</tt> - default: depends on which columns are present,
        #   The name of the database field where your encrypted password is stored. If the name of the field is different from any of the following
        #   you need to specify it with this option: crypted_password, encrypted_password, password_hash, pw_hash
        #
        # * <tt>password_blank_message</tt> - default: "can not be blank",
        #   The error message used when the password is left blank.
        #
        # * <tt>confirm_password_did_not_match_message</tt> - default: "did not match",
        #   The error message used when the confirm password does not match the password
        #   
        # * <tt>password_salt_field</tt> - default: :password_salt, :pw_salt, or :salt, depending on which column is present, defaults to :password_salt if none are present,
        #   This is the name of the field in your database that stores your password salt.
        #   
        # * <tt>remember_token_field</tt> - default: :remember_token, :remember_key, :cookie_tokien, or :cookie_key, depending on which column is present, defaults to :remember_token if none are present,
        #   This is the name of the field your remember_token is stored. The remember token is a unique token that is stored in the users cookie and
        #   session. This way you have complete control of when sessions expire and you don't have to change passwords to expire sessions. This also
        #   ensures that stale sessions can not be persisted. By stale, I mean sessions that are logged in using an outdated password.
        #   
        # * <tt>scope</tt> - default: nil,
        #   This scopes validations. If all of your users belong to an account you might want to scope everything to the account. Just pass :account_id
        #   
        # * <tt>logged_in_timeout</tt> - default: 10.minutes,
        #   This is a nifty feature to tell if a user is logged in or not. It's based on activity. So if the user in inactive longer than
        #   the value passed here they are assumed "logged out". This uses the last_request_at field, this field must be present for this option to take effect.
        #   
        # * <tt>session_ids</tt> - default: [nil],
        #   The sessions that we want to automatically reset when a user is created or updated so you don't have to worry about this. Set to [] to disable.
        #   Should be an array of ids. See the Authlogic::Session documentation for information on ids. The order is important.
        #   The first id should be your main session, the session they need to log into first. This is generally nil. When you don't specify an id
        #   in your session you are really just inexplicitly saying you want to use the id of nil.
        module Config
          def first_column_to_exist(*columns_to_check) # :nodoc:
            columns_to_check.each { |column_name| return column_name.to_sym if column_names.include?(column_name.to_s) }
            columns_to_check.first ? columns_to_check.first.to_sym : nil
          end
        
          def acts_as_authentic_with_config(options = {})
            options[:session_class] ||= "#{name}Session"
            options[:crypto_provider] ||= CryptoProviders::Sha512
            options[:login_field] ||= first_column_to_exist(:login, :username, :email)
            options[:login_field_type] ||= options[:login_field] == :email ? :email : :login
          
            case options[:login_field_type]
            when :email
              email_name_regex  = '[\w\.%\+\-]+'
              domain_head_regex = '(?:[A-Z0-9\-]+\.)+'
              domain_tld_regex  = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'
              options[:login_field_regex] ||= /\A#{email_name_regex}@#{domain_head_regex}#{domain_tld_regex}\z/i
              options[:login_field_regex_failed_message] ||= "should look like an email address."
            else
              options[:login_field_regex] ||= /\A\w[\w\.\-_@ ]+\z/
              options[:login_field_regex_failed_message] ||= "use only letters, numbers, spaces, and .-_@ please."
            end
          
            options[:password_field] ||= :password
            options[:password_blank_message] ||= "can not be blank"
            options[:confirm_password_did_not_match_message] ||= "did not match"
            options[:crypted_password_field] ||= first_column_to_exist(:crypted_password, :encrypted_password, :password_hash, :pw_hash)
            options[:password_salt_field] ||= first_column_to_exist(:password_salt, :pw_salt, :salt)
            options[:remember_token_field] ||= first_column_to_exist(:remember_token, :remember_key, :cookie_token, :cookiey_key)
            options[:single_access_token_field] ||= first_column_to_exist(nil, :single_access_token, :feed_token, :feeds_token)
            options[:logged_in_timeout] ||= 10.minutes
            options[:logged_in_timeout] = options[:logged_in_timeout].to_i
            options[:session_ids] ||= [nil]
          
            class_eval <<-"end_eval", __FILE__, __LINE__
              def self.acts_as_authentic_config
                #{options.inspect}
              end
            end_eval
          
            acts_as_authentic_without_config(options)
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  class << self
    include Authlogic::ORMAdapters::ActiveRecordAdapter::ActsAsAuthentic::Config
    alias_method_chain :acts_as_authentic, :config
  end
end