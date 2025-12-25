# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Setting, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:var) }
    # Uniqueness validation requires an existing record or subject
  end
end
