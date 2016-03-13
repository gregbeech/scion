require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module ParamDirectives
      include RouteDirectives

      def param_hash
        extract_request do |request|
          yield request.param_hash
        end
      end

      def params(*param_defs)
        param_hash do |hash|
          values = Array(param_defs).map do |param_def|
            if param_def.respond_to?(:has_key?)
              name, settings = param_def.each_pair.first
              value = hash.fetch(name, settings[:default])
              value = convert_param_type(value, settings[:type]) if settings.has_key?(:type)
            else
              value = hash[param_def]
            end
          end
          yield *values
        end
      end

      private

      def convert_param_type(value, type)
        if type == String then value
        elsif type == Symbol then value.to_sym
        elsif type == Bignum || type == Fixnum || type == Integer then Integer(value)
        elsif type == Float then Float(value)
        elsif type == BigDecimal then BigDecimal(v)
        else
          begin
            send(type.to_s, value)
          rescue NoMethodError
            raise "No type constructor found for #{type}"
          end
        end
      end
    end
  end
end