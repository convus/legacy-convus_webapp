class GithubIntegration
  CONTENT_GIT_PATH = ENV["CONTENT_GIT_PATH"].presence || "convus/convus_content"

  def self.content_html_url(file_path)
    ["https://github.com", CONTENT_GIT_PATH, "blob/main", file_path].join("/")
  end
end
