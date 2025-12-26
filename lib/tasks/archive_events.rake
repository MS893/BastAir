# frozen_string_literal: true

# lib/tasks/archive_events.rake
namespace :calendar do
  desc 'Archive old events in Google Calendars by changing their color and title.'
  task archive_old_events: :environment do
    puts 'Starting task to archive old Google Calendar events...'

    # Define which calendars to process. Add more from your .env file as needed.
    calendar_ids = [
      ENV.fetch('GOOGLE_CALENDAR_ID', nil),
      ENV.fetch('GOOGLE_CALENDAR_ID_EVENTS', nil),
      ENV.fetch('GOOGLE_CALENDAR_ID_AVION_F_HGBT', nil),
      ENV.fetch('GOOGLE_CALENDAR_ID_AVION_F_HGCU', nil)
    ]
    # Ajoute dynamiquement les calendriers de tous les instructeurs
    calendar_ids += User.where.not(google_calendar_id: nil).pluck(:google_calendar_id)
    calendar_ids = calendar_ids.compact.uniq

    # Define the cutoff date. Events older than this will be archived.
    cutoff_date = 1.year.ago

    service = GoogleCalendarService.new

    calendar_ids.each do |cal_id|
      puts "\nProcessing calendar: #{cal_id}"
      begin
        archived_count = service.archive_old_events(cal_id, cutoff_date)
        puts "-> Archived #{archived_count} event(s)."
      rescue StandardError => e
        puts "!! ERROR processing calendar #{cal_id}: #{e.message}"
      end
    end

    puts "\nTask finished."
  end
end
