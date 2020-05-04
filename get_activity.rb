require "json"
require "yaml"
require 'net/http'
require 'httparty'
require 'csv'
require 'open-uri'

COOKIE=ENV['COOKIE']
ROUTE_NAME = "allez_ronde"


colors = [
  '#00ff00',
  '#ff4400',
  '#ffcc00',
  '#ff00cc',
  '#0088ff',
  '#ccff00',
  '#7400d9',
  '#2ca600',
  '#a65800',
  '#6b0073',
  '#005c73',
  '#526600',
  '#594700',
  '#0a004d',
  '#402200',
  '#400000',
  '#002b40',
  '#ff4073',
  '#36d9b8',
  '#b22d2d',
  '#731d34',
  '#1a3866',
  '#165928',
  '#40103d',
  '#e680ff',
  '#ffa280',
  '#79baf2',
  '#dee673',
  '#73cfe6',
  '#e5b073',
  '#d96c98',
  '#6559b3',
  '#bef2b6',
  '#827ca6',
  '#a67c7c',
  '#7ca69d',
  '#a3a67c',
  '#3c4d39',
  '#4b394d',
  '#403030',
]

# activities = [
#   { id: 3286084243, name: "Andreas" },
#   { id: 3286704210, name: "Charlotte" },
#   { id: 3286100220, name: "Brian (Organizer)" },
#   { id: 3290682743, name: "Michael" },
#   { id: 3279901841, name: "Daniel" },
#   { id: 3285884294, name: "Hannah" },
#   { id: 3285588960, name: "Evan" },
#   { id: 3286070678, name: "Tanner" },
#   { id: 3284741117, name: "Jesse" },
#   { id: 3281175314, name: "Vincent" },
# ]
activities = []

CSV.new(open("https://docs.google.com/spreadsheets/u/0/d/12YuHFcPwVsVCPc6orXS8JGdcuoo11yQ8IoiX9HS5r3o/export?gid=206671802&format=csv"), headers: :first_row).each do |line|
  name = line[2]
  link = line[5]

  if link && name
    #https://strava.app.link/QKAL0yuA25
    if (link.include?("strava.app.link") )
      page = HTTParty.get(link.strip)
      strava_id = page[/activities\/(\d+)/].split("/").last
      puts "strava split: " + strava_id
    end

    #https://www.strava.com/activities/3382139871
    if (link.include?("strava.com"))
      strava_id = link[/activities\/(\d+)/].split("/").last
      puts "strava_id url: " + strava_id
    end

    activities.push({ name: name, id: strava_id}) unless !link

  end
end

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

####
File.write("./raw_activity/#{activity[:id]}.geojson", geojson.to_json)

  timing_data = data["latlng"].map.with_index do |latlng, i|
    {
      point: { lat: latlng[0], lng: latlng[1] },
      time: data["time"][i]
    }
  end

###
File.write("./raw_activity/#{activity[:id]}-timing.json", timing_data.to_json)

  total_time = data["time"].last
  time_display = "#{total_time / 3600}:#{total_time / 60 % 60}:#{total_time % 60}"



  activity_yaml << {
    "name" =>  activity[:name],
    "color" => "#" + Random.new.bytes(3).unpack("H*")[0],
    "id" => activity[:id].to_s,
    "distance" => 0.0,
    "time" => time_display,
    "timeSeconds" => total_time,
    "routeName" => "#{activity[:id]}.geojson",
    "timingData" => "#{activity[:id]}-timing.json",
  }
end

activity_yaml = activity_yaml.sort_by { |a| a["timeSeconds"] }.map.with_index { |a, i| a["color"] = colors[i]; a }

File.write("./_data/#{ROUTE_NAME}_routes.yml", activity_yaml.to_yaml)
File.write("./routes/#{ROUTE_NAME}.json", activity_yaml.to_json)