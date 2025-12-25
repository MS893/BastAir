# frozen_string_literal: true

class ProgressionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_access, only: [:show]
  before_action :authorize_student_area!

  def show
    if current_user.instructeur? || current_user.admin?
      # Pour les instructeurs, on liste les élèves pour la sélection.
      # On exclut les comptes BIA qui ne sont pas des élèves pilotes.
      @eleves = User.joins(:livrets).distinct.where('LOWER(fonction) IN (?)', %w[eleve brevete]).where.not('LOWER(prenom) = ?', 'bia').order(
        :nom, :prenom
      )

      # Si un élève est sélectionné via les paramètres, on le charge.
      if params[:eleve_id].present?
        @selected_eleve = User.find(params[:eleve_id])
        user_livrets = Livret.where(user: @selected_eleve)
      end
    else
      # Pour un élève, on affiche directement son propre livret.
      @selected_eleve = current_user
      user_livrets = Livret.where(user: current_user)
    end

    if user_livrets
      @examens_theoriques = user_livrets.where(course_id: nil, flight_lesson_id: nil).order(:id)
      @formations_theoriques = user_livrets.where.not(course_id: nil).order(:id)
      @lecons_en_vol = user_livrets.where.not(flight_lesson_id: nil).order(:flight_lesson_id, :id)
    else
      @examens_theoriques = Livret.none
      @formations_theoriques = Livret.none
      @lecons_en_vol = Livret.none
    end
  end

  def download
    @selected_eleve = if params[:eleve_id].present? && (current_user.instructeur? || current_user.admin?)
                        User.find(params[:eleve_id])
                      else
                        current_user
                      end
    @pdf = true

    # On définit @eleves pour que le formulaire dans la vue ne cause pas d'erreur, même s'il n'est pas affiché dans le PDF.
    @eleves = User.joins(:livrets).distinct.where('LOWER(fonction) IN (?)', %w[eleve brevete]).where.not('LOWER(prenom) = ?', 'bia').order(
      :nom, :prenom
    )

    user_livrets = Livret.where(user: @selected_eleve)
    @examens_theoriques = user_livrets.where(course_id: nil, flight_lesson_id: nil).order(:id)
    @formations_theoriques = user_livrets.where.not(course_id: nil).order(:id)
    @lecons_en_vol = user_livrets.where.not(flight_lesson_id: nil).order(:id)

    render  pdf: "Livret_progression_#{@selected_eleve.full_name.parameterize}_#{Date.today.strftime('%d-%m-%Y')}",
            template: 'progressions/show',
            layout: 'pdf',
            page_size: 'A4',
            orientation: 'Portrait',
            zoom: 1,
            dpi: 75,
            margin: { top: 30, bottom: 20, left: 10, right: 10 },
            header: { html: { template: 'layouts/_pdf_progression_header', layout: false }, spacing: 10 },
            footer: { html: { template: 'layouts/_pdf_footer', layout: false, formats: [:html] } }
  end

  def update_exam
    # Vérification des droits : instructeur ou admin uniquement
    unless current_user.instructeur? || current_user.admin?
      redirect_to root_path, alert: "Vous n'avez pas l'autorisation d'effectuer cette action."
      return
    end

    @selected_eleve = User.find(params[:eleve_id])

    exam_date = params[:user][:date_fin_formation]
    update_attributes = { date_fin_formation: exam_date }

    if exam_date.present?
      update_attributes[:fonction] = 'brevete'
      update_attributes[:date_licence] = exam_date
    else
      update_attributes[:fonction] = 'eleve'
      update_attributes[:date_licence] = nil
    end

    if @selected_eleve.update(update_attributes)
      redirect_to livret_progression_path(eleve_id: @selected_eleve.id),
                  notice: "Statut de l'examen pratique et profil élève mis à jour."
    else
      redirect_to livret_progression_path(eleve_id: @selected_eleve.id),
                  alert: "Erreur lors de la mise à jour : #{@selected_eleve.errors.full_messages.join(', ')}"
    end
  end

  def send_exam_email
    # Vérification des droits : instructeur ou admin uniquement
    unless current_user.instructeur? || current_user.admin?
      redirect_to root_path, alert: "Vous n'avez pas l'autorisation d'effectuer cette action."
      return
    end

    @selected_eleve = User.find(params[:eleve_id])

    if @selected_eleve.date_fin_formation.present?
      UserMailer.exam_success_email(@selected_eleve).deliver_later

      # On enregistre l'action dans les logs pour savoir que l'email a été envoyé
      ActivityLog.create(
        user: current_user,
        action: 'send_exam_email',
        record_type: 'User',
        record_id: @selected_eleve.id,
        details: "Email de félicitations envoyé à #{@selected_eleve.full_name}"
      )
      redirect_to livret_progression_path(eleve_id: @selected_eleve.id),
                  notice: "Email de félicitations envoyé à l'élève."
    else
      redirect_to livret_progression_path(eleve_id: @selected_eleve.id), alert: "L'examen pratique n'est pas validé."
    end
  end

  def send_pdf_email
    @selected_eleve = if params[:eleve_id].present? && (current_user.instructeur? || current_user.admin?)
                        User.find(params[:eleve_id])
                      else
                        current_user
                      end
    @pdf = true

    # Préparation des données (identique à l'action download)
    @eleves = User.joins(:livrets).distinct.where('LOWER(fonction) IN (?)', %w[eleve brevete]).where.not('LOWER(prenom) = ?', 'bia').order(
      :nom, :prenom
    )
    user_livrets = Livret.where(user: @selected_eleve)
    @examens_theoriques = user_livrets.where(course_id: nil, flight_lesson_id: nil).order(:id)
    @formations_theoriques = user_livrets.where.not(course_id: nil).order(:id)
    @lecons_en_vol = user_livrets.where.not(flight_lesson_id: nil).order(:id)

    # Génération du PDF en mémoire
    pdf = render_to_string(
      pdf: "Livret_progression_#{@selected_eleve.full_name.parameterize}_#{Date.today.strftime('%d-%m-%Y')}",
      template: 'progressions/show',
      layout: 'pdf',
      page_size: 'A4',
      orientation: 'Portrait',
      zoom: 1,
      dpi: 75,
      margin: { top: 30, bottom: 20, left: 10, right: 10 },
      header: { html: { template: 'layouts/_pdf_progression_header', layout: false }, spacing: 10 },
      footer: { html: { template: 'layouts/_pdf_footer', layout: false, formats: [:html] } }
    )

    UserMailer.progression_booklet_email(@selected_eleve, pdf).deliver_later
    redirect_to livret_progression_path(eleve_id: @selected_eleve.id),
                notice: "Le livret de progression a été envoyé par email à #{@selected_eleve.full_name}."
  end

  private

  def authorize_access
    # Seuls les élèves et les instructeurs peuvent accéder à cette page.
    return if current_user.eleve? || current_user.instructeur? || current_user.admin?

    redirect_to root_path,
                alert: "Vous n'avez pas l'autorisation d'accéder à cette page."
  end
end
