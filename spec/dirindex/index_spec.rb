describe Dirindex::Index do

  context "new initialized object wihout files" do
    before(:each) {
      @tempdir = Pathname.new("/tmp/dirindextest")
      @tempdir.rm_rf
      @tempdir.mkdir
    }
    
    subject { Index.new(@tempdir) }
    
    its("indexfile") { should == @tempdir + "dirindex.index" }
    its("datafile")  { should == @tempdir + "dirindex" }
    
  end

end
