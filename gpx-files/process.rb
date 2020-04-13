require 'json'

json_files = Dir[ './*[^_].json' ].select{ |f| File.file? f }

json_files.each do |json|
  begin
    data = JSON.parse(File.read(json))
    start_time = data["stream"][0]["time"]
    normalized = data["stream"].map { |d|
      { point: d["point"], elevation: d["elevation"], time: d["time"] - start_time }
    }
    File.write("./route_timings/#{json.split(".")[1]}_normalized.json", normalized.to_json)
  rescue
    # puts e
    puts json
  end
end
