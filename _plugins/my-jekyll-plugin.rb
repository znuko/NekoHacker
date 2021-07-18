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

      tracks.each do |track|
        if track["artists"]
          # puts track["artists"]
          # track["artists"] = 
          track["artists"].clean!
          # puts track["artists"]
        end
      end
      
      ## track["title"]とtrack["short_title"]のどちらかが欠けていれば、一方の値で補う
      tracks.each do |track|
        if track["title"].nil? || track["title"].empty?
          track["title"] = track["short_title"]
        elsif track["short_title"].nil? || track["title"].empty?
          track["short_title"] = track["title"]
        end
      end

      ## track["id"]を設定
      tracks.each do |track|
        track["id"] = URI.escape(track["title"].gsub(" ", "_"))
      end

      ## artist["id"]を設定
      artists.each do |artist|
        artist["id"] = URI.escape(artist["name"].gsub(" ", "_"))
      end

      ## projectのidを設定
      projects.each do |project|
        project["id"] = URI.escape(project["title"].gsub(" ", "_"))
      end

      ## artist[key]のvalueがひとつも登録されていなければ、artistsをnilにする
      tracks.each do |track|
        # artist_values = track["artists"]&.map {|a| a&.values} &.join
        # if artist_values.nil? || artist_values.empty?
        #   track["artists"] = nil
        # end

        # track["artists"] = clean(track["artists"])
        # track["artists"]&.clean!
      end

      ## track["artist"]がartists.ymlで登録されているかの真理値を追加
      registered_artist_names = artists.map {|a| a["name"]}
      complete_tracks = tracks.select {|t| t["artists"]}
      complete_tracks.each do |track|
        track["artists"].each do |artist|
          if registered_artist_names.include?(artist["name"])
            artist["is_registered"] = true
          else
            # artist["is_registered"] = false
          end
        end
      end



      ## artistページへのurlを設定
      tracks.each do |track|
        track["artists"]&.each do |artist|
          if artist["is_registered"]
            artist["url"] = site.config["baseurl"].chomp("/") + "/artist/#" + URI.escape(artist["name"].gsub(" ", "_"))
          end
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


      ## trackにprojectからの情報を追加
      tracks.each do |track|
        ## track["projects"][key]のvalueがひとつも登録されていなければ、
        ## track["projects"]を[]にする
        values = track["projects"]&.map {|t| t&.values} &.join
        if values.nil? || values.empty?
          track["projects"] = []
        end
        ## projects.ymlからprojectを探して設定
        projects.each do |project|
          project_titles = project["tracks"]&.map {|t| t["title"]}
          if project_titles&.include?(track["title"])
            project_url = site.config["baseurl"].chomp("/") + "/project/#" + project["id"]
            track["projects"].push({
              "title" => project["title"],
              "type" => project["type"],
              "release" => project["release"],
              "url" => project_url
            })
          end
        end
        ## 結局、projectがなければ[]からnilに戻す
        if track["projects"] == []
          track["projects"] = nil
        end
      end

      ## project["tracks"]のtrackがtracks.ymlで登録されているかの真理値を追加
      registered_track_titles = tracks.map {|t| t["title"]}
      projects.each do |project|
        project["tracks"]&.each do |track|
          if registered_track_titles.include?(track["title"])
            track["is_registered"] = true
          else
            track["is_registered"] = false
          end
        end
      end

      ## projects["tracks"]にtrackへのURLを追加
      projects.each do |project|
        project["tracks"].each do |track|
          if track["is_registered"]
            track["url"] = site.config["baseurl"].chomp("/") + "/#" + URI.escape(track["title"].gsub(" ", "_"))
          end
        end
      end





    end # of def

  end
end