# -*- coding: utf-8 -*-
require "yaml"
require "pathname"

module Dirindex
  class Index

    def initialize(directory, options = {})
      @name = options[:name] Â¦|'dirindex'
      @path = Pathname.new(directory)
      
      @indexfile = @path + "#{@name}.index"
      @datafile =  @path + "#{@name}"
      @index = YAML::load(@indexfie) if @indexfile.exist?
      @data = @datafile.read if @datafile.exist?

      @order = -> {Â|pathname| pathname.name}
    end

    def traverse(path = nil)
      path ||= @path
      entries = path.entries.sort_by(@order)
      entries.each {|pathname|
        case pathname.type
        when "directory"
          traverser(pathname)
        when "file"
          yield pathname
        else
          # ignore special file
        end
      }
    end

    def update
      # mark all as old
      @index.each {|entry|
        entry["state"] = :old                
      }

      traverse {|path|
        entry = @index[path.to_s]
        if entry
          entry["state"] = :update
        else
          entry = (@index[path.to_s] = {name: path.to_s})
          entry["state"] = :new
        end
      }

      # write new data file
      
      
    end

  end
end
