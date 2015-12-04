require 'iks_scrape'

module Prvak
	module Finance
		class IKSPortfolio
			CONFIGURATION_FILE = Pathname.new('~/dropbox/finance/iks-portfolio.yml').expand_path

			def self.load(file = CONFIGURATION_FILE)
				data = YAML.load_file(file)
				assets = data["assets"] or raise "No assets owned."
				invested = data["invested"] or raise "No initial investment specified"

				new(invested: invested, assets: assets)
			end

			def initialize(invested: nil, assets: nil)
				@invested, @assets = invested, assets
				@data = nil
			end

			def value
				scrape_if_needed

				@assets.map do |name, count|
					if @data.key?(name)
						@data[name][:price] * count
					else
						raise "Unknown asset #{name}"
					end
				end.select { |x| x }.inject(&:+)
			end

			def gain
				scrape_if_needed
				value - @invested
			end

			def gain_percentage
				scrape_if_needed
				gain / @invested * 100.0
			end

			def date
				scrape_if_needed
				@assets.map { |name, _count| @data[name][:date] }.compact.max
			end

			private

			def scrape_if_needed
				@data = IksScrape::Scraper.new.scrape unless @data

				if (@assets.keys - @data.keys).any?
					puts "ERROR: the following assets weren't found: #{@assets.keys - @data.keys}"
					puts "Known assets:"
					pp @data
					exit 1
				end
			end
		end
	end
end
