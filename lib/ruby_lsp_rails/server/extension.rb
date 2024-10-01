# typed: strict
# frozen_string_literal: true

require_relative "../runner_client"

module RubyLsp
  module Rails
    class Server
      module Types
        ResourceCallback = T.type_alias do
          T.proc.params(params: T::Hash[Symbol, T.anything]).returns(T::Hash[Symbol, T.anything])
        end
        VoidCallback = T.type_alias { T.proc.void }
      end

      class << self
        extend T::Sig

        sig { returns(T.nilable(T::Array[Types::VoidCallback])) }
        attr_accessor :start_callbacks

        sig { returns(T.nilable(T::Array[Types::VoidCallback])) }
        attr_accessor :shutdown_callbacks

        sig { returns(T.nilable(T::Array[Types::VoidCallback])) }
        attr_accessor :reload_callbacks

        sig { returns(T::Hash[Symbol, Types::ResourceCallback]) }
        def extension_resources
          @extension_resources ||= T.let({}, T.nilable(T::Hash[Symbol, Types::ResourceCallback]))
        end

        sig { params(name: Symbol, blk: Types::ResourceCallback).void }
        def define_extension_resource(name, &blk)
          # TODO: use namespacing to get around duplication?
          if extension_resources.key?(name.to_sym)
            raise KeyError, "Resource #{name} is already defined"
          end

          extension_resources[name.to_sym] = blk
        end

        sig { params(func: Types::VoidCallback).void }
        def add_start_callback(func)
          @start_callbacks ||= []
          @start_callbacks << func
        end

        sig { params(func: Types::VoidCallback).void }
        def add_reload_callback(func)
          @reload_callbacks ||= []
          @reload_callbacks << func
        end

        sig { params(func: Types::VoidCallback).void }
        def add_shutdown_callback(func)
          @shutdown_callbacks ||= []
          @shutdown_callbacks << func
        end
      end

      class Extension
        class << self
          extend T::Sig

          sig { params(name: Symbol, blk: Types::ResourceCallback).void }
          def resource(name, &blk)
            Server.define_extension_resource(name, &blk)
            RunnerClient.define_method(:"get_#{name}") do |**params|
              T.bind(self, RunnerClient)
              make_request(name.to_s, **params)
            end
          end

          sig { params(blk: Types::VoidCallback).void }
          def before_start(&blk)
            Server.add_start_callback(blk)
          end

          sig { params(blk: Types::VoidCallback).void }
          def before_shutdown(&blk)
            Server.add_shutdown_callback(blk)
          end

          sig { params(blk: Types::VoidCallback).void }
          def after_reload(&blk)
            Server.add_reload_callback(blk)
          end

          sig { returns(RunnerClient) }
          def client
            RunnerClient.instance
          end

          sig { params(klass: T::Class[T.anything]).void }
          def inherited(klass)
            super
            $stderr.write("Discovered ruby-lsp-rails extension #{klass.name}")
          end
        end
      end
    end
  end
end
