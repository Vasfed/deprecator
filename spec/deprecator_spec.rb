require 'rspec/autorun'
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
        Class.new{ deprecated_class "abc" }
      end
      it "class methods" do
        subject.strategy.should_receive(:class_found).with(kind_of(Class), duck_type(:to_s), "aa", []).once
        subject.strategy.should_receive(:plain_deprecated).with("bb", duck_type(:to_s), [])
        (Class.new{
          deprecated_class "aa"
          def self.cls_method; deprecated "bb"; end
        }).cls_method
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
      it "via call to deprecated" do
        subject.strategy.should_receive(:class_found).with(kind_of(Module), duck_type(:to_s), "abc", [])
        Module.new{ deprecated_class "abc" }
      end
    end

    context "methods" do
      before{
        subject.strategy = :base
      }
      it "simple" do
        subject.strategy.should_receive(:plain_deprecated).with("reason", duck_type(:to_s), [])
        deprecated "reason"
      end

      it "raise_deprecated" do
        expect{ raise_deprecated }.to raise_error(Deprecator::Deprecated)
      end

      it "marking in class" do
        cls = Class.new{
          deprecated_method "reason"
          def meth; end
          }
        subject.strategy.should_receive(:method_called).with(cls, :meth, "reason", /#{Regexp.escape __FILE__}:#{__LINE__+1}/, /#{Regexp.escape __FILE__}:#{__LINE__-3}/)
        cls.new.meth
      end

      it "deprecation by name defines method" do
        cls = Class.new{
          deprecated_method :meth, "reason"
          }
        subject.strategy.should_receive(:method_called).with(cls, :meth, "reason", /#{Regexp.escape __FILE__}:#{__LINE__+1}/, /#{Regexp.escape __FILE__}:#{__LINE__-2}/)
        cls.new.meth
      end
    end
  end

  context "strategy" do
    context "also installs hooks for class instantiation" do
      before{ subject.strategy = :base }
      it "without a reason passed" do
        cls = Class.new(DEPRECATED::Class)
        subject.strategy.should_receive(:object_found).with(cls, kind_of(cls), nil, /#{Regexp.escape __FILE__}:#{__LINE__+1}/, /#{Regexp.escape __FILE__}:#{__LINE__-1}/)
        cls.new
      end

      it "with reason passed" do
        cls = Class.new{ deprecated_class "reason" }
        subject.strategy.should_receive(:object_found).with(cls, kind_of(cls), "reason", /#{Regexp.escape __FILE__}:#{__LINE__+1}/, /#{Regexp.escape __FILE__}:#{__LINE__-1}/)
        cls.new
      end

      it "and guards for initialize method" do
        cls = Class.new{
          deprecated_class "reason"
          # def self.method_added(name); puts "method added #{name}"; end
          def initialize
            self.class.initialize_called
          end
        }
        cls.should_receive(:initialize_called).once
        subject.strategy.should_receive(:object_found).with(cls, kind_of(cls), "reason", /#{Regexp.escape __FILE__}:#{__LINE__+1}/, /#{Regexp.escape __FILE__}:#{__LINE__-7}/)
        cls.new
      end
    end

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
        subject.strategy = :warning
        subject.strategy.should be_a(Deprecator::Strategy::Warning)
      end
      it "raises on wrong strategy name" do
        expect{ subject.strategy = :no_such_strategy }.to raise_error(Deprecator::UnknownStrategy)
      end
    end

    it "with" do
      expect{
        subject.with_strategy(Object) do
          deprecated
        end
      }.to raise_error(NoMethodError, /plain_deprecated/)
    end
  end
end