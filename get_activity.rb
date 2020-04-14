require "json"
require "yaml"
require 'net/http'
require 'httparty'

COOKIE=???
ROUTE_NAME = "allez_ronde"

activities = [3286297313]

activity_yaml = []
for activity in activities do
  filename = "./raw_activity/#{activity}.json"
  data = nil
  if (File.exist?(filename))
    data = JSON.parse(File.read(filename))
  else
    data = HTTParty.get("https://strava.com/activities/#{activity}/streams?stream_types[]=latlng&stream_types[]=time&stream_types[]=altitude", { headers: { Cookie: COOKIE } })
    File.write(filename, data)
  end
  geojson = {
    type: "FeatureCollection",
    features: [
      {
        type: "Feature",
        properties: {
          name: activity.to_s,
          type: 1
        },
        geometry: {
          type: "LineString",
          coordinates: data["latlng"].map{ |array| [array[1], array[0]]}
        }
      }
    ]
  }
  File.write("./raw_activity/#{activity}.geojson", geojson.to_json)

  timing_data = data["latlng"].map.with_index do |latlng, i|
    {
      point: { lat: latlng[0], lng: latlng[1] },
      time: data["time"][i]
    }
  end
  File.write("./raw_activity/#{activity}-timing.json", timing_data.to_json)

  activity_yaml << {
    "name" =>  activity.to_s,
    "color" => "#" + Random.new.bytes(3).unpack("H*")[0],
    "id" => activity.to_s,
    "distance" => 0.0,
    "time" => "0:00",
    "routeName" => "#{activity}.geojson",
    "timingData" => "#{activity}-timing.json",
  }
end

File.write("./_data/#{ROUTE_NAME}_routes.yml", activity_yaml.to_yaml)