require 'yahoo_stock'
require 'yaml'
require 'pathname'
require 'bigdecimal'
require 'terminal-table'

module Prvak
	module Finance
		module Stocks
			Stock = Struct.new(:name, :latest_value)

			class StockRegistry
				def initialize
					@data = {}
				end

				def request_data(symbols)
					YahooStock::Quote.new(
						stock_symbols: symbols,
						# Use realtime bid if available.
						# Otherwise, fallback to non-realtime bid.
						# BUT - the exchange might be closed now. Therefore, we also
						# need to fallback to last close.
						read_parameters: [:symbol, :name, :bid, :bid_real_time, :previous_close]
					).results(:to_hash).output.each do |stock|
						current_symbol = stock[:symbol]
						unless symbols.include?(current_symbol)
							raise "Symbol not requested: #{current_symbol}"
						end

						bid_string =
							# (real-time bids seemed weird)
							# if sane_amount?(stock[:bid_real_time])
							# 	stock[:bid_real_time]
							# elsif sane_amount?(stock[:bid])
							if sane_amount?(stock[:bid])
								stock[:bid]
							elsif sane_amount?(stock[:previous_close])
								stock[:previous_close]
							else
								STDERR.puts "Cannot get bid data for #{current_symbol}!"
								STDERR.puts stock.inspect
								raise 'Cannot get bid'
							end
						bid = BigDecimal.new(bid_string)

						raise "Unexpected: penny stock! Check Yahoo sanitization." if bid < 0.01

						@data[current_symbol.to_sym] = Stock.new(stock[:name], bid)
					end

					unless symbols.all? { |symbol| @data.key?(symbol.to_sym) }
						raise "Not all symbols successfully fetched"
					end
				end

				def [](symbol)
					@data[symbol.to_sym]
				end

				private

				def sane_amount?(string_from_yahoo)
					string_from_yahoo != 'N/A' && string_from_yahoo != '0.00' && string_from_yahoo != '1.00'
				end
			end

			class Portfolio
				# A "hash" from symbols to amounts, possibly with additional cash

				def initialize(stocks: nil, cash_usd: 0, cash_czk: 0)
					raise ArgumentError unless stocks
					@stocks = stocks
					@cash_usd, @cash_czk = cash_usd, cash_czk
				end

				def self.load
					config = YAML.load_file(Pathname.new("~/.stock-portfolio.yml").expand_path)
					new(
						stocks: config['stocks'],
						cash_usd: BigDecimal.new(config['USD'], 3),
						cash_czk: BigDecimal.new(config['CZK'], 3)
					)
				end

				def usd_cash
					@cash_usd
				end

				def czk_cash
					@cash_czk
				end

				def symbols
					@stocks.keys
				end

				def each_symbol_amount(&block)
					@stocks.each(&block)
				end

				def map_symbol_amount
					@stocks.map { |symbol, amount| yield(symbol, amount) }
				end

				def stock_value_usd(registry)
					@stocks.map { |symbol, amount|
						registry[symbol].latest_value * amount
					}.inject(&:+)
				end
			end

			class StatusReport
				# * Stocks, each priced in USD
				# * Currently held USD
				# * Currently held CZK

				# TODO: refactor usd_to_czk
				def self.build(portfolio, registry, usd_to_czk)
					new(
						cash: {
							czk: portfolio.czk_cash,
							usd: portfolio.usd_cash
						},
						stocks: portfolio.map_symbol_amount { |symbol, amount|
							[
								symbol,
								{
									name: registry[symbol].name,
									owned: amount,
									usd_price: registry[symbol].latest_value
								}
							]
						}.to_h,
						usd_to_czk: usd_to_czk
					)
				end

				def initialize(cash: nil, stocks: nil, usd_to_czk: nil)
					@cash, @stocks, @usd_to_czk = cash, stocks, usd_to_czk
				end

				def stock_value_usd
					@stocks.values.map { |hash|
						hash[:owned] * hash[:usd_price]
					}.inject(&:+)
				end

				def cash_usd
					@cash[:usd]
				end

				def cash_czk
					@cash[:czk]
				end

				def total_value_czk
					@usd_to_czk.call(cash_usd + stock_value_usd) + cash_czk
				end

				def terminal_table
					Terminal::Table.new do |t|
						t << [
							'Symbol', 'Name', 'Owned stocks',
							'USD/stock', 'CZK/stock', 'Total CZK value'
						]
						t << :separator

						@stocks.each do |symbol, hash|
							t << [
								symbol, hash[:name], hash[:owned],
								"%.2f" % hash[:usd_price],
								"%.2f" % @usd_to_czk.call(hash[:usd_price]),
								"%.2f" % (hash[:owned] * @usd_to_czk.call(hash[:usd_price]))
							]
						end
					end
				end
			end
		end
	end
end
