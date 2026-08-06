Geocoder.configure(
  lookup: :nominatim,
  timeout: 5,
  units: :km,
  http_headers: { "User-Agent" => "AULABS/1.0 (dev)" }
)

if Rails.env.test?
  Geocoder.configure(lookup: :test)
end
