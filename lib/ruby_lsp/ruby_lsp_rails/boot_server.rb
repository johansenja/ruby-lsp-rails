# typed: false
# frozen_string_literal: true

require "ruby_lsp_rails/server"

RubyLsp::Rails::Server.new.start if ARGV.first == "start"
