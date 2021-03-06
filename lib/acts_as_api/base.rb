module ActsAsApi
  # This module enriches the ActiveRecord::Base module of Rails.
  module Base
    # Indicates if the current model acts as api.
    # False by default.
    def acts_as_api?
      false
    end

    # When invoked, it enriches the current model with the
    # class and instance methods to act as api.
    def acts_as_api

      class_eval do
        include ActsAsApi::Base::InstanceMethods
        extend ActsAsApi::Base::ClassMethods
      end

      if block_given?
        yield ActsAsApi::Config
      end

    end

    module ClassMethods

      def acts_as_api?#:nodoc:
        self.included_modules.include?(InstanceMethods)
      end

      # Determines the attributes, methods of the model that are accessible in the api response.
      # *Note*: There is only whitelisting for api accessible attributes.
      # So once the model acts as api, you have to determine all attributes here that should
      # be contained in the api responses.
      def api_accessible(api_template, options = {}, &block)

        attributes = api_accessible_attributes(api_template) || ApiTemplate.create(api_template)

        attributes.merge!(api_accessible_attributes(options[:extend])) if options[:extend]

        if block_given?
          yield attributes
        end

        write_inheritable_attribute("api_accessible_#{api_template}".to_sym, attributes)
      end

      # Returns an array of all the attributes that have been made accessible to the api response.
      def api_accessible_attributes(api_template)
        read_inheritable_attribute("api_accessible_#{api_template}".to_sym)
      end
    end

    module InstanceMethods

      # Creates the api response of the model and returns it as a Hash.
      # Will raise an exception if the passed api template is not defined for the model
      def as_api_response(api_template)
        api_attributes = self.class.api_accessible_attributes(api_template)
        
        raise ActsAsApi::TemplateNotFoundError.new("acts_as_api template :#{api_template.to_s} was not found for model #{self.class}") if api_attributes.nil?
        
        api_attributes.to_response_hash(self)
      end

    end

  end

end
