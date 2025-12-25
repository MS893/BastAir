require 'rails_helper'

RSpec.describe Tarif, type: :model do
  it "can be instantiated" do
    expect(Tarif.new).to be_a(Tarif)
  end
end