require "yaml"
require "pathname"

module Dirindex
 
  class Index    
    attr_reader :indexfile, :datafile, :data

    def initialize(directory, options = {})
      @name = options[:name] || 'dirindex'
      @path = Pathname.new(directory)
      
      @indexfile = @path + "#{@name}.index"
      @datafile =  @path + "#{@name}"
      @index = YAML::load(@indexfile.read) if @indexfile.exist?
      @data = @datafile.read if @datafile.exist?

      @index_function = options[:index_function] || 
        ->(pathname){
        Dirindex::LOGGER.debug("Call default index function with #{pathname.to_s}")
        pathname.to_s + "\n"
      }
      @order = ->(pathname){ pathname.to_s }
    end

    def init
      newindex = @path + "#{@name}.index.new"
      newdata  = @path + "#{@name}.new"
      raise "#{newdata.to_s } already exists" if newdata.exist?
      raise "#{newindex.to_s} already exists" if newindex.exist?

      @index = {}

      newdata.open("w") {|newdata_f|
        FileUtils.cd(@path) {
          traverse {|pathname|
            i = {}
            i[:start] = newdata_f.pos
            newdata_f.write(@index_function.call(pathname))
            i[:end] = newdata_f.pos          
            @index[pathname.to_s] = i
          }         
        }
      }

      newindex.open("w") {|newindex_f|
        newindex_f.write(@index.to_yaml)
      }
      
      FileUtils.mv(newdata, @datafile)
      FileUtils.mv(newindex, @indexfile)
      @data = @datafile.read
    end

    def update
      return init
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

    def index_of(file)
      _index = @index[file.to_s]
      return nil unless _index
      @data[_index[:start].._index[:end]-1]
    end

    def traverse(path = nil, &block)
      Dirindex::LOGGER.debug("Traversing #{path.to_s}")
     
      entries = (path || Pathname.new(".")).entries
      unless path
        to_reject = ["#{@name}", "#{@name}.index","#{@name}.new", "#{@name}.index.new"]
        entries.reject! {|p| to_reject.include?(p.to_s)}
      end
      entries.sort_by!(&@order)
      entries.each {|pathname|
        next if [".",".."].include?(pathname.to_s)
        pathname = path + pathname if path

        case pathname.ftype
        when "directory"
          traverse(pathname, &block)
        when "file"
          Dirindex::LOGGER.debug("Yield file #{pathname.to_s}")
          yield pathname
        else
          puts "Ignoring #{pathname.ftype.inspect}"
          # ignore special file
        end
      }
    end

  end
end
