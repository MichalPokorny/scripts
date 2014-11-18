# TODO: tfuj
require_relative '../../btckit/bank.rb'
require_relative '../../btckit/config.rb'

module Prvak
	module Finance
		module Currency
			BTCKIT_CONFIG = BtcKit::Config.new
			BANK = BtcKit::Bank.new(BTCKIT_CONFIG.bank_filename)

			def self.usd_to_czk(amount_in_usd)
				BANK.exchange(amount_in_usd, 'USD', 'CZK').cents
			end
		end
	end
end
