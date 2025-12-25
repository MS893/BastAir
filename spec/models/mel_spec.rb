# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mel, type: :model do
  it 'is valid with valid attributes' do
    expect(Mel.new).to be_valid
  end
end
