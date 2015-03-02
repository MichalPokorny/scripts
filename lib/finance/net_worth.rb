require_relative 'homebank'
require_relative 'iks_portfolio'
require 'parallel'

module Prvak
	module Finance
		module NetWorth
			# Look out: the order matters (for CSV output)
			ASSETS = [
				{ name: 'Účty a peníze', lambda: -> {
					Prvak::Finance::Homebank::Accounting.load.total_value
				} },
				{ name: 'IKS fondy', lambda: -> {
					Prvak::Finance::IKSPortfolio.load.value
				} },
				{ name: 'Bitcoiny', command: 'worthy -mode bitcoin' },
				{ name: 'Akcie', command: 'worthy -mode broker' },
				{ name: 'EUR účet', command: 'worthy -mode euro_account' }
			]

			class AssetReadingFailed < StandardError
				def initialize(asset)
					@asset = asset
				end

				# TODO: custom nice message
			end

			# Returns { 'asset name' => current value }:
			#		{ 'Účty a peníze' => 9998765.43, ... }
			def self.load_assets
				Parallel.map(ASSETS) { |asset|
					if asset[:command]
						result = `#{asset[:command]}`.to_f
						if $?.exitstatus != 0
							puts "#{asset[:command]} failed"
							raise AssetReadingFailed.new(asset[:name])
						end

						[asset[:name], result]
					elsif asset[:lambda]
						begin
							[asset[:name], asset[:lambda].call]
						rescue => exception
							require 'pp'
							# TODO: log original exception
							pp exception
							raise AssetReadingFailed.new(asset[:name])
						end
					else
						raise "Invalid asset #{asset[:name]}"
					end
				}.to_h
			end

			def self.load_assets_lazy
				if @cached_assets
					@cached_assets
				else
					@cached_assets = load_assets
				end
			end

			def self.net_worth
				load_assets_lazy.values.inject(&:+)
			end
		end
	end
end
