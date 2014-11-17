module Prvak
	def self.xosdutil_say(text)
		system 'xosdutilctl', 'echo', text
	end
end
