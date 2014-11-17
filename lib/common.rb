require 'pathname'

module Prvak
	DOWNLOAD_DIR = Pathname.new('~/downloads').expand_path.to_s
end
