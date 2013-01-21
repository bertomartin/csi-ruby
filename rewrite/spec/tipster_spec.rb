require 'dalli'
require_relative '../tipster'
require_relative '../tidbit'

module Gossip
  def self.cache
    @cache ||= Dalli::Client.new('127.0.0.1:11211', :namespace => 'gossip')
  end
end

describe Gossip::Tipster do

  before(:all) do
    begin
      Gossip.cache.set('running', true)
    rescue Dalli::RingError => e
      fail "You need to have memcached running"
    end
  end

  before(:each) do
    Gossip::Tipster.stub(:cache_expiration => 1)
  end

  let(:tidbit) do
    charlie = User.new('Charlie Suarez', 'charlie@example.com')
    Gossip::Tidbit.new(1, :recipient => 'Tom Baker', :created_by => charlie)
  end

  subject { Gossip::Tipster.new(tidbit, :tipper => 'Alice', :emails => 'bob@example.com') }

  describe "basic attributes" do
    its(:tidbit) { should eq(tidbit) }
    its(:tipper) { should eq('Alice') }
    its(:emails) { should eq(['bob@example.com']) }
    its(:failed_emails) { should eq([]) }
  end

  describe "tipper" do
    it "cleans up whitespace in the name" do
      subject.tipper = ' Alice     Smith   '
      subject.tipper.should eq('Alice Smith')
    end

    it "is required" do
      ->{ Gossip::Tipster.new(tidbit, :emails => 'one@example.com') }.should raise_error Gossip::Tipster::UnacceptableName
    end

    it "cannot be an empty string" do
      ->{ Gossip::Tipster.new(tidbit, :tipper => '', :emails => 'one@example.com') }.should raise_error Gossip::Tipster::UnacceptableName
    end
  end

  describe "emails" do
    specify "are required" do
      ->{ Gossip::Tipster.new(tidbit, :tipper => 'Alice') }.should raise_error Gossip::Tipster::MissingEmail
    end

    specify "cannot be an empty list" do
      ->{ Gossip::Tipster.new(tidbit, :tipper => 'Alice', :emails => '') }.should raise_error Gossip::Tipster::MissingEmail
    end

    it "accepts a comma separated list" do
      subject.emails = 'one@example.com,two@example.com, three@example.com'
      subject.emails.should eq(%w(one@example.com two@example.com three@example.com))
    end

    it "discards duplicates" do
      subject.emails = 'one@example.com,two@example.com,two@example.com'
      subject.emails.should eq(%w(one@example.com two@example.com))
    end
  end

  describe "dispatching emails" do
    it "works" do
      subject.should_receive(:dispatch_to).once.with('bob@example.com')
      subject.tip!
    end

    it "marks as tipped" do
      Pony.stub(:mail)

      subject.dispatch_to('alice@example.com')
      subject.dispatched_emails.should eq(['alice@example.com'])
    end

    it "marks as failed when it blows up" do
      Pony.stub(:mail).and_raise 'Oh noes'

      subject.dispatch_to('alice@example.com')
      subject.failed_emails.should eq(['alice@example.com'])
    end
  end

  it "doesn't spam" do
    Pony.should_receive(:mail).once
    subject.emails = 'nospam@example.com'

    subject.tip!
    subject.tip!
  end

  # I don't know how to test this without actually waiting.
  # Sorry :(
  it "will spam again after the cache expires" do
    Pony.should_receive(:mail).twice
    subject.emails = 'spamagain@example.com'

    subject.tip!
    sleep 1
    subject.tip!
  end
end
