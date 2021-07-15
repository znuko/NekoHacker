require "jekyll"

module Jekyll
  class DataSetting < Generator
    def generate(site)
      # site.config['hoge'] = {}
      # site.config['hoge']['aho'] = 'boke'
      # site.config["unko"] = "aaaa"
      # site.data["music"].each do |track|
      #   track["aaa"] = "にゃあ"
      # end

      site.data["music"].each do |track|
        track["releases"] = []
      end

      site.data["projects"].each do |project|
        if project["release"] && project["music"] then

          track_titles = []
          project["music"].each do |track|
            track_titles << track["title"]
          end

          tracks = site.data["music"].select do |track|
            track_titles.include?(track["official_title"])
          end

          tracks.each do |track|
            track["releases"] << project["release"]
          end

        end
      end

      site.data["music"].each do |track|
        track["releases"].sort!
        track["release_first"] = track["releases"][0]
      end

      complete_music = site.data["music"].select {|t| t["release_first"]}
      complete_music.sort_by! {|track| track["release_first"]}
      incomplete_music = site.data["music"].select {|t| !t["release_first"]}
      site.data["music"] = complete_music += incomplete_music

    end # of def
  end
end