require 'dirindex'

describe Dirindex::Index do

  before(:each) {
    @tempdir = Pathname.new("/tmp/dirindextest")
    @tempdir.rmtree if @tempdir.exist?
    @tempdir.mkdir
    (@tempdir + "adir").mkdir
    FileUtils.touch @tempdir + "another"
    FileUtils.touch @tempdir + "adir/afile"
    
  }
  subject { Dirindex::Index.new(@tempdir) }

  context "new object wihout files" do        
    its("indexfile") { should == @tempdir + "dirindex.index" }
    its("datafile")  { should == @tempdir + "dirindex" }    
    its("data") { should == nil }

    { "initialized" => ->(x){subject.init},
      "initialized and updated" => ->(x){subject.init;subject.update},
      "initialized and loaded"  => ->(x){subject.init; Dirindex::Index.new(@tempdir)}
    }.each {|name, block|
      context name do
        before(:each, &block)
        
        its("data") { should == "adir/afile\nanother\n" }
        
        it "should generate indexfile and index" do
          (@tempdir + "dirindex").exist?.should be_true
          (@tempdir + "dirindex.index").exist?.should be_true
        end

        it "should return index for files" do
          subject.index_of("another").should == "another\n"
          subject.index_of("adir/afile").should == "adir/afile\n"
        end

        it "sould not call index function anymore" do
          index_function = mock
          subject.instance_eval do @index_function = index_function end
          subject.update
        end

      end
    }
  end
    
end
