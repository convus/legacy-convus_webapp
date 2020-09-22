require "rails_helper"

RSpec.describe GithubIntegration do
  let(:subject) { described_class.new }

  describe "main_branch_ref" do
    let(:target) { "b26302f7f2872653dece0c814a31401a0653963c" }
    it "gets the main branch sha" do
      VCR.use_cassette("github_integration-main_branch_sha", match_requests_on: [:method]) do
        expect(subject.main_branch_sha).to eq target
      end
    end
  end

  describe "create_hypothesis_pull_request" do
    let(:hypothesis) do
      hy = Hypothesis.create(title: "Testing GitHub integration")
      hy.update_column :id, 42 # So we get consistent PRs
      hy
    end

    def branches(client)
      subject.refs.map(&:ref).uniq
    end

    def open_pull_requests(client)
      subject.pull_requests(state: "open")
    end

    it "creates the pull request" do
      expect(hypothesis.pull_request_number).to be_blank
      # When changing this - you have to remove any existing refs for branches named the same.
      # Delete it either by closing the PR: https://github.com/convus/convus_content/pulls
      # Or deleting the branch manually (if PR wasn't created): https://github.com/convus/convus_content/branches
      VCR.use_cassette("github_integration-create_hypothesis_pull_request", match_requests_on: [:method]) do
        initial_branch_count = branches(subject.client).count
        initial_pull_requests = open_pull_requests(subject.client)
        pull_request = subject.create_hypothesis_pull_request(hypothesis)
        expect(branches(subject.client).count).to be > initial_branch_count
        prs = open_pull_requests(subject.client)
        expect(prs.count).to be > initial_pull_requests.count
        hypothesis.reload
        expect(hypothesis.pull_request_number).to be_present

        # Can't do this via octokit.rb right now. BUT OH GOT THIS IS SOMETHING WE WANT
        # expect(pull_request.maintainer_can_modify).to be_truthy
      end
    end
  end
end
