require_relative 'tinyurl'

describe Gossip::Tinyurl do
  before(:each) do
    Gossip::Tinyurl.class_variable_set :@@lookup_tiny_urls, {}
    Gossip::Tinyurl.stub(:environment => 'production')
  end

  it "works" do
    Gossip::Tinyurl.shorten("http://kytrinyx.com").should eq("http://is.gd/5rzpAN")
  end

  it "caches" do
    Gossip::Tinyurl.should_receive(:lookup_tiny_url).once.and_return {"http://short.url"}
    Gossip::Tinyurl.shorten("http://google.com")
    Gossip::Tinyurl.shorten("http://google.com")
  end

  it "just returns the original url on errors" do
    result = stub(:code => 409)
    Net::HTTP.stub(:start => result)
    Gossip::Tinyurl.shorten("http://example.com").should eq('http://example.com')
  end

  specify "well, not all errors" do
    result = stub(:code => 500)
    Net::HTTP.stub(:start => result)
    # Not sure what actually causes the API to return 500
    ->{ Gossip::Tinyurl.shorten("http://something.com") }.should raise_error Gossip::Tinyurl::InvalidUrlException
  end

  it "doesn't worry about invalid urls" do
    Gossip::Tinyurl.shorten("invalidurl").should eq("invalidurl")
  end

  it "swallows timeouts, returning the unshortened url" do
    Net::HTTP.stub(:start).and_raise(Timeout::Error)
    Gossip::Tinyurl.shorten("http://timeout.com").should eq("http://timeout.com")
  end

  it "works in staging, too" do
    Gossip::Tinyurl.stub(:environment => 'staging')
    Gossip::Tinyurl.shorten("http://kytrinyx.com").should == 'http://is.gd/5rzpAN'
  end

  it "doesn't actually work in development" do
    Gossip::Tinyurl.stub(:environment => 'development')
    Gossip::Tinyurl.shorten("http://xkcd.com/1110").should == nil
  end

  it "doesn't work in test, either" do
    Gossip::Tinyurl.stub(:environment => 'test')
    Gossip::Tinyurl.shorten("http://thedailywtf.com").should == nil
  end
end
