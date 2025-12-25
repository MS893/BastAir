# frozen_string_literal: true

require 'test_helper'

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    test 'should get new' do
      get admin_users_new_url
      assert_response :success
    end

    test 'should get create' do
      get admin_users_create_url
      assert_response :success
    end
  end
end
