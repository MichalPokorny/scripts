#!/usr/bin/ruby
require 'fileutils'
require 'pathname'
require 'highline'

require_relative 'lib/common'

class Unduplicator
	def self.find_directory_duplicates(directory)
		find_duplicates(Dir[Pathname.new(directory).expand_path.to_s + "/*"])
	end

	def self.find_duplicates(files)
		Duplicates.new(
			files.map do |f|
				if f =~ /^(.*)\((\d+)\)\.([^.]*)$/
					alt = "#$1.#$3"
					f if File.exist?(alt) && are_same_files?(f, alt)
				end
			end.compact
		)
	end

	def self.are_same_files?(x, y)
		File::Stat.new(x).size == File::Stat.new(y).size &&
			File.read(x) == File.read(y)
	end
end

class UndupDownloads
	def interact(duplicates, go: false, verbose: false)
		if duplicates.any?
			if go || duplicates.confirm_deletion?
				duplicates.drop!
				true
			else
				puts "Doing nothing."
				false
			end
		else
			if verbose
				puts 'No duplicates.'
			end

			true
		end
	end
end

class Duplicates
	def initialize(duplicates)
		@duplicates = duplicates
	end

	def any?
		@duplicates.any?
	end

	def drop!
		puts "OK, deleting #{@duplicates.size} files."
		@duplicates.each { |p| FileUtils.rm(p) }
		@duplicates = []
	end

	def each(&block)
		@duplicates.each(&block)
	end

	def confirm_deletion?
		each(&method(:puts))
		puts
		HighLine.new.agree("Delete the files? [y/n] ")
	end
end

if __FILE__ == $0
	go = false
	path = Prvak::DOWNLOAD_DIR

	case ARGV[0]
	when "--go"
		go = true
	when String
		path = ARGV[0]
	end

	ARGV.shift

	duplicates = Unduplicator.find_directory_duplicates(path)
	UndupDownloads.new.interact(duplicates, go: go)
end
