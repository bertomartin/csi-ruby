require 'rack/test'
require 'json'
require 'dalli'
require 'pony'
require_relative '../v1'

module Gossip
  def self.cache
    @cache ||= Dalli::Client.new('127.0.0.1:11211', :namespace => 'gossip')
  end

  TIDBITS = {
    1 => Tidbit.new(1, :recipient => 'Bob Smith', :created_by => User.new('Alice Smith', 'alice@example.com')),
    2 => Tidbit.new(2, :recipient => 'Indira Smith', :created_by => User.new('Bob Smith', nil))
  }
end

class TestGossipV1 < GossipV1; end

describe "Gossip" do
  include Rack::Test::Methods

  def app
    TestGossipV1
  end

  # These are more like observations than tests.

  before(:all) do
    begin
      Gossip.cache.set('running', true)
    rescue Dalli::RingError => e
      fail "You need to have memcached running"
    end
  end

  before(:each) do
    Gossip::Sharing.stub(:cache_expiration => 1)
  end

  it "works" do
    Pony.should_receive(:mail).twice
    get '/share_by_email_or_sms/1', :name => "Charlie", :emails => 'abe@example.com,beth@example.com'
    JSON.parse(last_response.body)["sent_to"].should eq(['abe@example.com', 'beth@example.com'])
  end

  it "doesn't complain if you don't give it recipients" do
    get "/share_by_email_or_sms/1"
    last_response.status.should eq(200)
    JSON.parse(last_response.body)["sent_to"].should eq([])
  end

  it "doesn't complain about a 40 char name" do
    get '/share_by_email_or_sms/1', :name => "x" * 40
    last_response.status.should eq(200)
    JSON.parse(last_response.body)["sent_to"].should eq([])
  end

  it "doesn't send with an invalid name" do
    Pony.should_not_receive(:mail)
    get '/share_by_email_or_sms/1', :name => "x"*42, :emails => 'chris@example.com'
    last_response.body.should eq('Invalid name')
  end

  it "is insane" do
    # It sends the emails, even though the name is supposedly invalid.
    Pony.should_receive(:mail)
    name_with_42_characters = "#{"x" * 20}  #{"x" * 20}"
    get '/share_by_email_or_sms/1', :name => name_with_42_characters, :emails => 'daryl@example.com'
  end

  it "complains about the wrong thing" do
    Pony.should_not_receive(:mail)
    # Daniel never gets the tip, poor sod.
    get '/share_by_email_or_sms/1', :name => " " * 40, :emails => 'daniel@example.com'
    last_response.status.should eq(400)
    last_response.body.should eq("Couldn't find any valid recipients who hadn't already received this tip.")
  end

  it "doesn't send duplicate emails" do
    Pony.should_receive(:mail).once
    get '/share_by_email_or_sms/1', :name => "Charlie", :emails => 'eve@example.com,eve@example.com'
    JSON.parse(last_response.body)["sent_to"].should eq(['eve@example.com'])
  end

  it "doesn't resend cached emails" do
    # cache Fred's email
    get '/share_by_email_or_sms/1', :name => "Charlie", :emails => 'fred@example.com'

    Pony.should_receive(:mail).once
    get '/share_by_email_or_sms/1', :name => "Charlie", :emails => 'greg@example.com,fred@example.com'
    JSON.parse(last_response.body)["sent_to"].should eq(['greg@example.com'])
  end

  it "returns an error if there are no sendable emails" do
    # cache Heidi's email
    get '/share_by_email_or_sms/1', :name => "Charlie", :emails => 'heidi@example.com'

    Pony.should_not_receive(:mail)
    get '/share_by_email_or_sms/1', :name => "Charlie", :emails => 'heidi@example.com'
    last_response.status.should eq(400)
    last_response.body.should eq("Couldn't find any valid recipients who hadn't already received this tip.")
  end

  it "says it sends it, but it doesn't" do
    # Bob didn't leave his email address.
    # This shouldn't matter, because we're trying to send to indira@example.com, not Bob.
    Pony.should_not_receive(:mail)

    get '/share_by_email_or_sms/2', :name => "Charlie", :emails => 'indira@example.com'
    JSON.parse(last_response.body)["sent_to"].should eq(['indira@example.com'])
  end

  it "doesn't send SMSs. Ever. Go see why, and be astonished."

  it "strips tokens" do
    Gossip::Sharing.get_tokens("a,,B ,\tc").should eq(%w(a b c))
  end

  it "defaults tokens to empty list" do
    Gossip::Sharing.get_tokens(nil).should eq([])
  end
end

