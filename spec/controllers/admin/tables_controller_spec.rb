require 'rails_helper'

RSpec.describe Admin::TablesController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let!(:avion) { create(:avion) }
  let(:table_name) { 'avions' }

  before { sign_in admin }

  describe "GET #index" do
    it "affiche la liste des enregistrements pour une table donnée" do
      get :index, params: { table_name: table_name }
      expect(response).to be_successful
      records = controller.instance_variable_get(:@records)
      expect(records.map(&:id)).to include(avion.id)
    end
  end

  describe "GET #edit_record" do
    it "affiche le formulaire d'édition" do
      get :edit_record, params: { table_name: table_name, id: avion.id }
      expect(response).to be_successful
      record = controller.instance_variable_get(:@record)
      expect(record.id).to eq(avion.id)
    end
  end

  describe "PATCH #update_record" do
    it "met à jour l'enregistrement" do
      patch :update_record, params: { table_name: table_name, id: avion.id, record: { marque: "Updated" } }
      expect(avion.reload.marque).to eq("Updated")
      expect(response).to redirect_to(admin_tables_path(table_name: table_name))
    end
  end

  describe "GET #new_record" do
    it "affiche le formulaire de création" do
      get :new_record, params: { table_name: table_name }
      expect(response).to be_successful
      record = controller.instance_variable_get(:@record)
      expect(record).to be_new_record
    end
  end

  describe "POST #create_record" do
    it "crée un nouvel enregistrement" do
      # Attributs valides pour un avion
      new_attributes = attributes_for(:avion).merge(immatriculation: "F-NEW")
      
      expect {
        post :create_record, params: { table_name: table_name, record: new_attributes }
      }.to change(Avion, :count).by(1)
      
      expect(response).to redirect_to(admin_tables_path(table_name: table_name))
    end
  end

  describe "DELETE #destroy_record" do
    it "supprime l'enregistrement" do
      avion_to_delete = create(:avion, immatriculation: "F-DEL")
      expect {
        delete :destroy_record, params: { table_name: table_name, id: avion_to_delete.id }
      }.to change(Avion, :count).by(-1)
      
      expect(response).to redirect_to(admin_tables_path(table_name: table_name))
    end
  end
end