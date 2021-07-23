# require "uri"
class Array
  def clean!
    values = self&.map {|hash| hash&.values} &.join
    if values.nil? || values.empty?
      puts self
      return self.replace([])
    end
  end
end

module Jekyll
  class DataSetting < Generator
    def generate(site)

      # site.data["music"].each do |track|
      #   track["releases"] = []
      # end

      # site.data["projects"].each do |project|
      #   if project["release"] && project["music"] then

      #     track_titles = []
      #     project["music"].each do |track|
      #       track_titles << track["title"]
      #     end

      #     tracks = site.data["music"].select do |track|
      #       track_titles.include?(track["official_title"])
      #     end

      #     tracks.each do |track|
      #       track["releases"] << project["release"]
      #     end

      #   end
      # end

      # site.data["music"].each do |track|
      #   track["releases"].sort!
      #   track["release_first"] = track["releases"][0]
      # end

      # complete_music = site.data["music"].select {|t| t["release_first"]}
      # complete_music.sort_by! {|track| track["release_first"]}
      # incomplete_music = site.data["music"].select {|t| !t["release_first"]}
      # site.data["music"] = complete_music += incomplete_music

      # def clean!
      #   values = self&.map {|h| h&.values} &.join
      #   if values.nil? || values.empty?
      #     return self&.replace(nil)
      #   end
      # end

tracks = site.data["tracks"]
artists = site.data["artists"]
projects = site.data["projects"]

warnings = []
errors = []

# cleaning
## nilなら[]で置き換え
tracks.each do |t|
  t["artists"] = t["artists"] || []
#   t["projects"] = t["projects"] || []
end


#
# データの欠損を補う
#

## track["title"]とtrack["short_title"]のどちらかが欠けていれば、一方の値で補う
tracks.each do |track|
  if track["title"].nil? || track["title"].empty?
    track["title"] = track["short_title"]
  elsif track["short_title"].nil? || track["title"].empty?
    track["short_title"] = track["title"]
  end
end

## artistのroleを配列にする
## roleとrolesのどっちで指定してもokにする
tracks.each do |track|
  track["artists"].each do |artist|
    artist["roles"] = artist["roles"] || []
    artist["role"] = [artist["role"]] unless artist["role"].is_a?(Array)
    artist["roles"] += artist["role"]
    artist["roles"].each{|r| r&.downcase!}.compact!
  end
end

## project["tracks"][key]のvalueがひとつも登録されていなければ、
## project["tracks"][0]["title"]をproject["title"]にする
projects.each do |project|
  tracks_values = project["tracks"]&.map {|t| t&.values} &.join
  if tracks_values.nil? || tracks_values.empty?
    project["tracks"] = [{"title" => project["title"]}]
  end
end

## projectのtrack numberを設定
projects.each do |project|
  num = 1
  project["tracks"].each do |track|
    if !track["num"].is_a?(Integer)
      track["num"] = num
    end
    num += 1
  end
end



#
# idの設定とファイル間の関連付け
#

## track["id"]を設定
tracks.each do |track|
  track["id"] = URI.escape(track["title"].gsub(" ", "_"))
  track["url"] = site.config["baseurl"].chomp("/") + "/#" + track["id"]
end

## artist["id"]を設定
artists.each do |artist|
  artist["id"] = URI.escape(artist["name"].gsub(" ", "_"))
  artist["url"] = site.config["baseurl"].chomp("/") + "/artist/#" + URI.escape(artist["name"].gsub(" ", "_"))
end

## projectのidを設定
projects.each do |project|
  project["id"] = URI.escape(project["title"].gsub(" ", "_"))
  project["url"] = site.config["baseurl"].chomp("/") + "/project/#" + project["id"]
end


## trackとartistの関連付け
## artist idとtrack idをそれぞれ追加
## もしartists.ymlにデータがなければ、artist idをnilにする
artists.each {|a| a["vocal_ids"] = []}
artists.each {|a| a["track_ids"] = []}
tracks.each do |track|
  track["artists"].each do |artist|
    matching_artist = artists.select {|a| a["name"] == artist["name"]} [0]
    if matching_artist.nil?
      warnings.push("no data in artists.yml: #{artist["name"]} | #{artist["roles"]} | #{track["short_title"]}")
      artist["id"] = nil
    else
      artist["id"] = matching_artist["id"]
      if artist["roles"].include?("vocal")
        matching_artist["vocal_ids"].push(track["id"]).uniq!
      else
        matching_artist["track_ids"].push(track["id"]).uniq!
      end
    end
  end
end

## trackとprojectの関連付け
## track idとproject idをそれぞれ追加
## もしtracks.ymlにデータがなければ、idをnilにする
tracks.each {|t| t["projects"] = t["projects"] || []}
projects.each do |project|
  project["tracks"].each do |track|
    matching_track = tracks.select {|t| t["title"] == track["title"]} [0]
    if matching_track.nil?
      warnings.push("no data in tracks.yml: #{track["title"]}")
      track["id"] = nil
    else
      track["id"] = matching_track["id"]
      matching_track["projects"].push({
        "id" => project["id"],
        "track_number" => track["num"]
        }).uniq!
    end
  end
end

#
# データの接続 join
#

# ## trackにartistの情報をjoin
# tracks.each do |track|
#   track["artists"].each do |x|
#     matching = artists.select {|m| m["id"] == x["id"]} [0]
#     x.merge!(matching) unless matching.nil?
#   end
# end

# ## trackにprojectの情報をjoin
# tracks.each do |track|
#   track["projects"].each do |x|
#     matching = projects.select {|m| m["id"] == x["id"]} [0]
#     x.merge!(matching) unless matching.nil?
#   end
# end


#
# データの追加
#

## trackのartistに、artistsページへのURLを追加
tracks.each do |track|
  track["artists"].each do |artist|
    next if artist["id"].nil?
    matching = artists.select {|a| a["id"] == artist["id"]} [0]
    artist["url"] = matching["url"]
  end
end

## projectのtrackに、tracksページへのURLを追加
projects.each do |project|
  project["tracks"].each do |track|
    next if track["id"].nil?
    matching = tracks.select {|t| t["id"] == track["id"]} [0]
    track["url"] = matching["url"]
  end
end

## trackにfirst release dateとsortのための番号を設定
tracks.each do |track|
  sorting_sets = []
  track["projects"].each do |project|
    matching_project = projects.select {|p| p["id"] == project["id"]} [0]
    sort_num = matching_project["release"].to_s + "-" + format('%02d', project["track_number"]).to_s
    sorting_sets.push({
      "date" => matching_project["release"],
      "num" => project["track_number"],
      "sort" => sort_num
    })
  end

  sort_num = track["release"].to_s + "-" + format('%02d', 0).to_s
  sorting_sets.push({
    "date" => track["release"],
    "num" => 0,
    "sort" => sort_num
  }).select! {|set| !set["date"].nil?}

  sorting_set = sorting_sets.sort_by {|h| h["sort"]} [0]

  if sorting_set.nil?
    warnings.push("no release setting: #{track["title"]}")
  else
    track["first_release"] = sorting_set["date"]
    track["sort"] = sorting_set["sort"]
  end
end

## tracksをreleas順でソート
sortables = tracks.select {|t| t["sort"]} .sort_by! {|t| t["sort"]}
unsortables = tracks.select {|t| !t["sort"]}
site.data["tracks"] = sortables + unsortables

## projectsをrelease順でソート
sortables = projects.select {|p| p["release"]} .sort_by! {|p| p["release"]}
unsortables = projects.select {|p| !p["release"]} 
site.data["projects"] = sortables + unsortables

## trackのprojectsをrelease順にソート
tracks.each do |track|
  sortables = track["projects"].select do |project|
    projects.select {|p| p["id"] == project["id"]} [0]["release"]
  end .sort_by! do |project|
    projects.select {|p| p["id"] == project["id"]} [0]["release"]
  end
  unsortables = track["projects"].select do |project|
    !projects.select {|p| p["id"] == project["id"]} [0]["release"]
  end
  track["projects"] = sortables + unsortables
end



####
site.config["warnings"] = warnings
site.config["errors"] = errors
##################################################

    end # of def

  end
end