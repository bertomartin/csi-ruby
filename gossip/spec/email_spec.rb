require_relative '../tidbit'
require_relative '../email'

describe Gossip::Email do
  let(:tidbit) { Gossip::Tidbit.new(1, :recipient => 'Auntie Alice', :created_by => User.new('Bob Smith', 'bob@example.com')) }

  it "looks like this" do
    email = Gossip::Email.new(tidbit, 'Charlie', 'alice@example.com')
    expected = <<-___
      Bob Smith has created a tidbit of gossip about Auntie Alice on example.com.
      Charlie would like you to take a look.

    Follow this link:
      http://example.com/ec1

    Join in the conversation by leaving a comment!
___
    email.body.should eq(expected)
  end
end
