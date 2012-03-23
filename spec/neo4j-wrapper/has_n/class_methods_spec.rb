require 'spec_helper'


describe Neo4j::Wrapper::HasN::ClassMethods do

  let(:base) do
    Class.new do
      extend Neo4j::Wrapper::HasN::ClassMethods
      def self.to_s
        "BaseClass"
      end

    end
  end

  let(:other) do
    Class.new do
      extend Neo4j::Wrapper::HasN::ClassMethods
      def self.to_s
        "OtherClass"
      end
    end
  end

  let(:sub) do
    s = Class.new(base)
    s.inherited(base)
    s
  end

  describe "#has_n :foo" do
    before do
      base.has_n :things
    end

    describe "foo (classmethod)" do
      subject { base.things}
      it { should == "things"}
    end

    describe "_decl_rels[:things]" do
      subject do
        base._decl_rels[:things]
      end

      it { should be_kind_of(Neo4j::Wrapper::HasN::DeclRel) }
      its(:has_one?) { should be_false }
      its(:rel_type) { should == :things }
      its(:target_class) { should == base }
      its(:source_class) { should == base }
      its(:dir) { should == :outgoing }
    end
  end

  describe "#has_n(:stuff).to(OtherClass)" do
    before do
      base.has_n(:stuff).to(other)
    end

    describe "stuff (classmethod)" do
      subject { base.stuff}
      it { should == "BaseClass#stuff"}
    end

    describe "_decl_rels[:stuff]" do
      subject do
        base._decl_rels[:stuff]
      end

      it { should be_kind_of(Neo4j::Wrapper::HasN::DeclRel) }
      its(:has_one?) { should be_false }
      its(:rel_type) { should == "BaseClass#stuff"}
      its(:target_class) { should == other }
      its(:source_class) { should == base }
      its(:dir) { should == :outgoing }
    end
  end

  describe "#has_n(:stuff).from(:knows)" do
    before do
      base.has_n(:known_by).from(:knows)
    end

    describe "stuff (classmethod)" do
      subject { base.known_by}
      it { should == "knows"}
    end

    describe "_decl_rels[:known_by]" do
      subject do
        base._decl_rels[:known_by]
      end

      it { should be_kind_of(Neo4j::Wrapper::HasN::DeclRel) }
      its(:has_one?) { should be_false }
      its(:rel_type) { should == :knows}
      its(:target_class) { should == base }
      its(:source_class) { should == base }
      its(:dir) { should == :incoming }
    end
  end

  describe "#has_n(:known_by).from(OtherClass, :knows)" do
    before do
      other.has_n(:knows)
      base.has_n(:known_by).from(other, :knows)
    end

    describe "_decl_rels[:known_by]" do
      subject do
        base._decl_rels[:known_by]
      end

      it { should be_kind_of(Neo4j::Wrapper::HasN::DeclRel) }
      its(:has_one?) { should be_false }
      its(:rel_type) { should == "OtherClass#knows"}
      its(:target_class) { should == other }
      its(:source_class) { should == base }
      its(:dir) { should == :incoming }
    end
  end

  describe "#has_one(:known_by).from(OtherClass, :knows)" do
    before do
      other.has_one(:knows)
      base.has_one(:known_by).from(other, :knows)
    end

    describe "stuff (known_by)" do
      subject { base.known_by}
      it { should == "OtherClass#knows"}
    end

    describe "_decl_rels[:known_by]" do
      subject do
        base._decl_rels[:known_by]
      end

      it { should be_kind_of(Neo4j::Wrapper::HasN::DeclRel) }
      its(:has_one?) { should be_true }
      its(:rel_type) { should == "OtherClass#knows"}
      its(:target_class) { should == other }
      its(:source_class) { should == base }
      its(:dir) { should == :incoming }
    end
  end

#    describe "#property :x, :conf1 => 'val1'" do
#      before do
#        base.property :x, :conf1 => 'val1'
#      end
#
#      it "should have configuration for property :x" do
#        base._decl_props[:x].should == {:conf1 => 'val1'}
#      end
#    end
#
#  end
#
#  context "for a subclass" do
#
#    before do
#      base.property :baaz
#      base.property :y, :conf1 => 'val2'
#    end
#
#    it "exist in the base class" do
#      base.property?(:baaz).should be_true
#    end
#
#    it "should inherit the properties" do
#      sub.property?(:baaz).should be_true
#    end
#
#    it "does not change the base class properties" do
#      sub.property :subp
#      base.property?(:subp).should be_false
#      sub.property?(:subp).should be_true
#    end
#
#    it "inherits configuration properties as well" do
#      base._decl_props[:y].should == {:conf1 => 'val2'}
#      sub._decl_props[:y].should == {:conf1 => 'val2'}
#    end
#  end
#end

end