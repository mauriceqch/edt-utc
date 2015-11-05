json.array!(@events) do |event|
  json.extract! event, :id, :course, :type, :date, :frequency, :classroom
  json.url event_url(event, format: :json)
end
