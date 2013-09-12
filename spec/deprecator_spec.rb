require 'rspec/autorun'
# require 'rr'
require 'deprecator'

describe Deprecator do
  subject{ Deprecator }

  context "deprecation marking of" do

    context "classes" do
      before{
        class DummyStrategy; end
        subject.strategy = DummyStrategy
      }
      it "via inheriting" do
        subject.strategy.should_receive(:class_found).with(kind_of(Class), duck_type(:to_s))
        Class.new(DEPRECATED::Class)
      end
      it "via extending" do
        subject.strategy.should_receive(:class_found).with(kind_of(Class), duck_type(:to_s))
        Class.new{ extend DEPRECATED }
      end
      it "via including" do
        subject.strategy.should_receive(:class_found).with(kind_of(Class), duck_type(:to_s))
        Class.new{ include DEPRECATED }
      end
      it "via call to deprecated" do
        subject.strategy.should_receive(:class_found).with(kind_of(Class), duck_type(:to_s), "abc", [])
        Class.new{ deprecated "abc" }
      end
    end

    context "modules" do
      it "via extending" do
        subject.strategy.should_receive(:class_found).with(kind_of(Module), duck_type(:to_s))
        Module.new{ extend DEPRECATED }
      end
      it "via including" do
        subject.strategy.should_receive(:class_found).with(kind_of(Module), duck_type(:to_s))
        Module.new{ include DEPRECATED }
      end
    end

    context "methods" do
      it "simple" do
        subject.strategy.should_receive(:deprecated).with("reason", duck_type(:to_s), [])
        deprecated "reason"
      end
    end
  end

  context "strategy" do
    context "set" do
      it "via object" do
        obj = Object.new
        subject.strategy = obj
        subject.strategy.should == obj
      end
      it "via class" do
        cls = Class.new
        subject.strategy = cls
        subject.strategy.should be_a cls
      end
      it "by symbolic name" do
        expect{ subject.strategy = :warning }.not_to raise_error
      end
      it "raises on wrong strategy name" do
        expect{ subject.strategy = :no_such_strategy }.to raise_error(Deprecator::UnknownStrategy)
      end
    end
  end
end