# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  def index
    categories = {
      recette: Transaction::INCOME_SOURCES.values,
      depense: Transaction::EXPENSE_SOURCES.values
    }
    render json: categories
  end
end
