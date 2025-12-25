# app/controllers/admin/news_items_controller.rb

# contrôleur des consignes
class Admin::NewsItemsController < Admin::BaseController
  before_action :set_news_item, only: [:edit, :update, :destroy]

  # GET /admin/news_items
  def index
    @news_items = NewsItem.order(created_at: :desc)
  end

  # GET /admin/news_items/new
  def new
    @news_item = NewsItem.new
  end

  # POST /admin/news_items
  def create
    @news_item = NewsItem.new(news_item_params)
    @news_item.user = current_user # On associe l'actualité à l'admin qui la crée

    if @news_item.save
      redirect_to admin_news_items_path, notice: 'Consigne créée avec succès.'
    else
      render :new, status: :unprocessable_content, alert: "Erreur lors de la création de la consigne."
    end
  end

  # GET /admin/news_items/:id/edit
  def edit
  end

  # PATCH/PUT /admin/news_items/:id
  def update
    if @news_item.update(news_item_params)
      redirect_to admin_news_items_path, notice: 'Consigne mise à jour avec succès.'
    else
      render :edit, status: :unprocessable_content, alert: "Erreur lors de la mise à jour de la consigne."
    end
  end

  # DELETE /admin/news_items/:id
  def destroy
    @news_item.destroy
    redirect_to admin_news_items_path, notice: 'Consigne supprimée avec succès.', status: :see_other
  end


  
  private

  def set_news_item
    @news_item = NewsItem.find(params[:id])
  end

  def news_item_params
    params.require(:news_item).permit(:title, :content)
  end

end
