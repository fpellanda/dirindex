module Dirindex
end
require "logger"
Dirindex::LOGGER = Logger.new(STDOUT)

require "dirindex/index"
