require 'rails_helper'

RSpec.describe FlightLesson, type: :model do
  describe "Validations" do
    it { should validate_presence_of(:title) }
  end
  
  it "can have a document attached" do
    expect(FlightLesson.new).to respond_to(:document)
  end
end