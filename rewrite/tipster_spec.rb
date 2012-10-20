require_relative 'tipster'

describe Gossip::Tipster do
  let(:e_card) { stub }

  subject { Gossip::Tipster.new(e_card, :tipper => 'Alice', :emails => 'bob@example.com') }

  describe "basic attributes" do
    its(:e_card) { should eq(e_card) }
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
      ->{ Gossip::Tipster.new(e_card, :email => 'email') }.should raise_error Gossip::Tipster::UnacceptableName
    end

    it "cannot be an empty string" do
      ->{ Gossip::Tipster.new(e_card, :tipper => '', :email => 'email') }.should raise_error Gossip::Tipster::UnacceptableName
    end
  end

  describe "emails" do
    specify "are required" do
      ->{ Gossip::Tipster.new(e_card, :tipper => 'Alice') }.should raise_error Gossip::Tipster::MissingEmail
    end

    specify "cannot be an empty list" do
      ->{ Gossip::Tipster.new(e_card, :tipper => 'Alice', :emails => '') }.should raise_error Gossip::Tipster::MissingEmail
    end

    it "accepts a comma separated list" do
      subject.emails = 'one,two, three'
      subject.emails.should eq(%w(one two three))
    end

    it "discards duplicates" do
      subject.emails = 'one,two,two'
      subject.emails.should eq(%w(one two))
    end
  end
end
