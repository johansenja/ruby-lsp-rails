# typed: false
# frozen_string_literal: true

require_relative "../runner_client"

module RubyLsp
  module Rails
    class Server
      class << self
        attr_accessor :start_callbacks
        attr_accessor :shutdown_callbacks
        attr_accessor :reload_callbacks

        def extension_capabilities
          @extension_capabilities ||= {}
        end

        def define_extension_capability(name, &blk)
          # TODO: use namespacing to get around duplication?
          if extension_capabilities.key?(name.to_sym)
            raise KeyError, "Capability #{name} is already defined"
          end

          extension_capabilities[name.to_sym] = blk
        end

        def add_start_callback(func)
          @start_callbacks ||= []
          @start_callbacks << func
        end

        def add_reload_callback(func)
          @reload_callbacks ||= []
          @reload_callbacks << func
        end

        def add_shutdown_callback(func)
          @shutdown_callbacks ||= []
          @shutdown_callbacks << func
        end
      end

      class Extension
        class << self
          def command(name, &blk)
            Server.define_extension_capability(name, &blk)
            RunnerClient.define_method(:"get_#{name}") do |**params|
              make_request(name.to_s, **params)
            end
          end

          def before_start(&blk)
            Server.add_start_callback(blk)
          end

          def before_shutdown
            Server.add_shutdown_callback(blk)
          end

          def after_reload(&blk)
            Server.add_reload_callback(blk)
          end

          def client
            RunnerClient.instance
          end

          def inherited(klass)
            super
            $stderr.write("Discovered ruby-lsp-rails extension #{klass.name}")
          end
        end
      end
    end
  end
end
