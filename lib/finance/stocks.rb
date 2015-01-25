require 'yaml'
require 'pathname'
require 'bigdecimal'

require_relative 'currency'

module Prvak
	module Finance
		module Stocks
			Stock = Struct.new(:name, :latest_value)

			def self.total_value_czk
				`worthy`.to_f.tap {
					raise if $?.exitstatus != 0
				}
			end
		end
	end
end
