# frozen_string_literal: true

module ElasticAPM
  module Spies
    class AwsSeahorseSpy
      TYPE = 'aws'

      def install
        ::Seahorse::Client::Request.class_eval do
          alias send_request_without_apm send_request

          def send_request(*args, &block)
            return send_request_without_apm(*args, &block) unless ElasticAPM.current_transaction

            operation_name = self.context.operation.name
            http_method = self.context.operation.http_method
            service_id = self.context.client.class.api.metadata&.[]('serviceId') || 'AWS'

            ElasticAPM.with_span(
              "#{service_id} #{operation_name}",
              TYPE,
              subtype: service_id,
              action: operation_name,
              context: Span::Context.new(http: { method: http_method })
            ) do
              AwsSeahorseSpy.without_http_spies do
                send_request_without_apm(*args, &block)
              end
            end
          end
        end
      end

      def self.without_http_spies(&block)
        return NetHTTPSpy.disable_in(&block) if defined?(NetHTTPSpy)

        yield
      end
    end

    register(
      'Seahorse::Client::Request',
      'aws-sdk-core',
      AwsSeahorseSpy.new
    )
  end
end
