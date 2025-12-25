# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Course, type: :model do
  describe 'Associations' do
    it { should have_many(:questions).dependent(:destroy) }
  end

  it 'can have a document attached' do
    expect(Course.new).to respond_to(:document)
  end
end
