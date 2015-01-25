# TODO: tfuj
require 'json'
require 'net/http'
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

			def self.eur_to_czk(amount_in_eur)
				body = Net::HTTP.get(URI.parse("http://www.freecurrencyconverterapi.com/api/v3/convert?q=EUR_CZK&compact=y"))
				JSON.parse(body)["EUR_CZK"]["val"] * amount_in_eur
			end
		end
	end
end
