module FlatFileSerializable
  extend ActiveSupport::Concern
  # NOTE: This requires file_pathnames & flat_file_serialized methods
  # Perhaps that should be enforced more explicitly enforced

  def file_path
    file_pathnames.join("/")
  end

  def flat_file_name(root_path)
    File.join(root_path, *file_pathnames)
  end

  def flat_file_content
    # Serialize to yaml - stringify keys so keys don't start with :, to make serialized file easier to read
    flat_file_serialized.deep_stringify_keys.to_yaml
  end

  # Overridden except on explanations, which are serialized into hypotheses
  def flat_file_serialized
    ""
  end

  def github_html_url
    approved? ? GithubIntegration.content_html_url(file_path) : pull_request_url
  end

  def pull_request_url
    GithubIntegration.pull_request_html_url(pull_request_number)
  end
end
