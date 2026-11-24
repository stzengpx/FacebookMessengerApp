cask "facebook-messenger-app" do
  version "1.6.0,20261117"
  sha256 "b4d443531e230b947d13c33f783745d28311181af48641144cab22cd98aefec1"

  url "https://github.com/KHeresy/FacebookMessengerApp/releases/download/v#{version.csv.first}%2B#{version.csv.second}/Facebook.Messenger-#{version.csv.first}-arm64.dmg"
  name "Facebook Messenger App"
  desc "Unofficial Facebook Messenger desktop application"
  homepage "https://github.com/KHeresy/FacebookMessengerApp"

  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)+)\+(\d{8})$/i)
    strategy :github_latest do |json, regex|
      json["tag_name"]&.match(regex) do |match|
        "#{match[1]},#{match[2]}"
      end
    end
  end

  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "Facebook Messenger.app"

  postflight_steps do
    run "/usr/bin/xattr",
        args: ["-cr", "{{appdir}}/Facebook Messenger.app"],
        sudo: true
  end
end
