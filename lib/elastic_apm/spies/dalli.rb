# frozen_string_literal: true

module ElasticAPM
  module Spies
    class DalliSpy
      TYPE = 'db'
      SUBTYPE = 'memcached'

      def install
        ::Dalli::Server.class_eval do
          alias request_without_apm request

          def request(op, *args, &block)
            return request_without_apm(op, *args, &block) unless ElasticAPM.current_transaction

            keys, = args
            keys = keys.join(' ') if keys.respond_to?(:join)

            ElasticAPM.with_span(
              keys ? "#{op.to_s.upcase} #{keys}" : op.to_s.upcase,
              TYPE,
              subtype: SUBTYPE,
              context: Span::Context.new(
                destination: {
                  name: SUBTYPE,
                  resource: SUBTYPE,
                  type: TYPE,
                  address: self.hostname,
                  port: self.port
                }
              )
            ) { request_without_apm(op, *args, &block) }
          end
        end
      end
    end

    register(
      'Dalli::Server',
      'dalli',
      DalliSpy.new
    )
  end
end
