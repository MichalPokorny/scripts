module Prvak
	module Finance
		module Independence
			OCTAVE_ROOT = File.dirname(__FILE__) + '/independence'

			def self.years_to_work(interest_rate: nil, savings_rate: nil, total_years: nil)
				raise unless interest_rate && interest_rate >= 0.0
				raise unless savings_rate && savings_rate >= 0.0 && savings_rate <= 1.0
				raise unless total_years && total_years >= 0.0

				# TODO: sanity check?
				result = `octave -q --path #{OCTAVE_ROOT} #{OCTAVE_ROOT}/interface-yearsToWork.m #{interest_rate} #{savings_rate} #{total_years}`
				raise unless $?.exitstatus == 0

				result.to_f
			end
		end
	end
end
