require 'rspec/autorun'
require 'deprecator'

describe Deprecator::Strategy::Warning do
  before{
    Deprecator.strategy = subject
  }
  it "calls warn" do
    subject.should_receive(:warn).with("[DEPRECATED] block (2 levels) in <top (required)> is deprecated!")
    subject.deprecated
  end

  it "raises on not implemented" do
    expect {
      not_implemented
    }.to raise_error(Deprecator::NotImplemented)
  end
end
