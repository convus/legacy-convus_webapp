# frozen_string_literal: true

require "rails_helper"

RSpec.describe "hypothesis_citations", type: :request do
  let(:base_url) { "/hypotheses/#{hypothesis.id}/citations" }
  let(:current_user) { nil }
  let!(:hypothesis) { FactoryBot.create(:hypothesis_approved) }
  let(:subject) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis) }

  let(:citation_params) do
    {
      title: "Testing hypothesis creation is very important",
      kind: "research_review",
      peer_reviewed: true,
      randomized_controlled_trial: true,
      url_is_direct_link_to_full_text: "0",
      authors_str: "\nZack\n George\n",
      published_date_str: "1990-12-2",
      url_is_not_publisher: false
    }
  end
  let(:citation_url) { "https://example.com/something-of-interest" }
  let(:quotes) do
    ["exposure to artificial light at night induces strong responses for physiological measures, daily activity patterns and life history traits.",
      "We found particularly strong responses with regards to hormone levels, the onset of daily activity in diurnal species and life history traits, such as the number of offspring, predation, cognition and seafinding (in turtles)."]
  end
  let(:quotes_text) { quotes.join("\n") }
  let(:hypothesis_citation_params) { {url: citation_url, quotes_text: quotes_text} }

  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "#{base_url}/new"
    end
  end

  describe "edit" do
    it "redirects" do
      get "#{base_url}/#{subject.to_param}/edit"
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "#{base_url}/#{subject.to_param}/edit"
    end
  end

  context "logged in" do
    include_context :logged_in_as_user

    describe "new" do
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypothesis_citations/new")
      end
    end

    describe "create" do
      it "creates" do
        expect(hypothesis.hypothesis_citations.count).to eq 0
        Sidekiq::Worker.clear_all
        expect {
          post base_url, params: {hypothesis_citation: hypothesis_citation_params}
        }.to change(HypothesisCitation, :count).by 1
        hypothesis.reload
        hypothesis_citation = hypothesis.hypothesis_citations.last
        expect(response).to redirect_to edit_hypothesis_citation_path(hypothesis_id: hypothesis.id, id: hypothesis_citation.id)
        expect(AddToGithubContentJob.jobs.count).to eq 0
        expect(flash[:success]).to be_present

        expect(hypothesis_citation.approved?).to be_falsey
        expect(hypothesis_citation.creator_id).to eq current_user.id
        expect(hypothesis_citation.url).to eq citation_url
        expect(hypothesis_citation.quotes_text_array).to match_array(quotes)
      end
    end
  end
end
