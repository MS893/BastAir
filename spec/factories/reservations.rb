FactoryBot.define do
  factory :reservation do
    association :user
    association :avion
    start_time { Time.now + 1.day }
    end_time { Time.now + 1.day + 1.hour }
    type_vol { "Standard" }
  end
end