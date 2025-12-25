require 'rails_helper'

RSpec.describe Immob, type: :model do
  it "can be instantiated" do
    expect(Immob.new).to be_a(Immob)
  end
end
