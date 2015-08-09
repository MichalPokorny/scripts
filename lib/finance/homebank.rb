# A severely limited Homebank parser and calculator

require 'pathname'
require 'nokogiri'

module Prvak
	module Finance
		module Homebank
			MAIN_ACCOUNTING_FILE = (Pathname.new('~/Dropbox/ucetnictvi.xhb')).expand_path

			class Account
				def initialize(name, key, initial)
					@name, @key, @initial = name, key, initial
					@operations = []
					@total = initial
				end

				def add_operation(op)
					@operations << op
					@total += op.amount
				end

				attr_reader :name, :total
			end

			class Operation
				def initialize(account, amount)
					@account, @amount = account, amount
				end

				attr_reader :account, :amount
			end

			class Accounting
				def self.load(filename = MAIN_ACCOUNTING_FILE)
					doc = Nokogiri::XML(open(filename))

					accounts = {}
					doc.xpath('//account').each do |account|
						# Type 3 = "assets account". We watch those ourselves.
						next if account.attribute("type").value.to_i == 3

						# Flags bit 2 probably means "closed".
						next if account.attribute("flags") && account.attribute("flags").value.to_i & 2

						key = account.attribute("key").value.to_i
						raise if accounts.key?(key)
						accounts[key] =
							Account.new(
								account.attribute("name").value,
								key,
								account.attribute("initial").value.to_f
							)
					end

					doc.xpath('//ope').each do |operation|
						acc = operation.attribute("account").value.to_i
						operation = Operation.new(
							acc,
							operation.attribute("amount").value.to_f
						)
						next unless accounts.key?(acc)
						accounts[acc].add_operation(operation)
					end

					new(accounts)
				end

				def initialize(accounts)
					@accounts = accounts
				end

				def accounts
					@accounts.values
				end

				def each_account(&block)
					@accounts.values.each(&block)
				end

				def total_value
					accounts.map(&:total).inject(&:+)
				end
			end
		end
	end
end
