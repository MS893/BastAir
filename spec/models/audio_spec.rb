require 'rails_helper'

RSpec.describe Audio, type: :model do
  it "can have an audio file attached" do
    expect(Audio.new).to respond_to(:audio)
  end
end