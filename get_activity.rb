require "json"
require "yaml"
require 'net/http'
require 'httparty'

COOKIE=""
ROUTE_NAME = "coronacat"

activities = [
  { id: 3286084243, name: "Andreas" },
  { id: 3286704210, name: "Charlotte" },
  { id: 3286100220, name: "Brian (Organizer)" },
  { id: 3290682743, name: "Michael" },
  { id: 3279901841, name: "Daniel" },
  { id: 3285884294, name: "Hannah" },
  { id: 3285588960, name: "Evan" },
  { id: 3286070678, name: "Tanner" },
  { id: 3284741117, name: "Jesse" },
  { id: 3281175314, name: "Vincent" },
]

activity_yaml = []
for activity in activities do
  filename = "./raw_activity/#{activity[:id]}.json"
  data = nil
  if (File.exist?(filename))
    data = JSON.parse(File.read(filename))
  else
    data = HTTParty.get("https://strava.com/activities/#{activity[:id]}/streams?stream_types[]=latlng&stream_types[]=time&stream_types[]=altitude", { headers: { Cookie: COOKIE } })
    File.write(filename, data)
  end
  geojson = {
    type: "FeatureCollection",
    features: [
      {
        type: "Feature",
        properties: {
          name: activity[:id].to_s,
          type: 1
        },
        geometry: {
          type: "LineString",
          coordinates: data["latlng"].map{ |array| [array[1], array[0]]}
        }
      }
    ]
  }
  File.write("./raw_activity/#{activity[:id]}.geojson", geojson.to_json)

  timing_data = data["latlng"].map.with_index do |latlng, i|
    {
      point: { lat: latlng[0], lng: latlng[1] },
      time: data["time"][i]
    }
  end
  File.write("./raw_activity/#{activity[:id]}-timing.json", timing_data.to_json)

  total_time = data["time"].last
  time_display = "#{total_time / 3600}:#{total_time / 60 % 60}:#{total_time % 60}"

  activity_yaml << {
    "name" =>  activity[:name],
    "color" => "#" + Random.new.bytes(3).unpack("H*")[0],
    "id" => activity[:id].to_s,
    "distance" => 0.0,
    "time" => time_display,
    "routeName" => "#{activity[:id]}.geojson",
    "timingData" => "#{activity[:id]}-timing.json",
  }
end

File.write("./_data/#{ROUTE_NAME}_routes.yml", activity_yaml.to_yaml)
File.write("./routes/#{ROUTE_NAME}.json", activity_yaml.to_json)