# frozen_string_literal: true

require "rails_helper"

RSpec.describe "hypothesis_citations", type: :request do
  let(:base_url) { "/hypotheses/#{hypothesis.id}/hypothesis_citations" }
  let(:hypothesis) { FactoryBot.create(:hypothesis_approved) }
  let(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis) }

  # let(:citation_params) do
  #   {
  #     title: "Testing hypothesis creation is very important",
  #     kind: "research_review",
  #     peer_reviewed: true,
  #     randomized_controlled_trial: true,
  #     url_is_direct_link_to_full_text: "0",
  #     authors_str: "\nZack\n George\n",
  #     published_date_str: "1990-12-2",
  #     url_is_not_publisher: false,
  #     quotes_text: "First quote from this literature\nSecond quote, which is cool\nThird"

  #   }
  # end
  # let(:full_citation_url) { "https://example.com/something-of-interest" }
  # let(:current_user) { nil }

  # describe "new" do
  #   it "redirects" do
  #     get "#{base_url}/new"
  #     expect(response).to redirect_to new_user_session_path
  #     expect(session[:user_return_to]).to eq "#{base_url}/new"
  #   end
  # end

  # describe "edit" do
  #   it "redirects" do
  #     get "#{base_url}/#{subject.to_param}/edit"
  #     expect(response).to redirect_to new_user_session_path
  #     expect(session[:user_return_to]).to eq "#{base_url}/#{subject.to_param}/edit"
  #   end
  # end

  # context "logged in" do
  #   include_context :logged_in_as_user

  #   describe "new" do
  #     it "renders" do
  #       get "#{base_url}/new"
  #       expect(response.code).to eq "200"
  #       expect(response).to render_template("hypotheses_citations/new")
  #     end
  #   end

  #   describe "create" do
  #     let(:creation_params) { citation_params.slice(:url)}
  #     it "creates" do
  #       expect(Hypothesis.count).to eq 0
  #       Sidekiq::Worker.clear_all
  #       expect {
  #         post base_url, params: {hypothesis: simple_hypothesis_params.merge(approved_at: Time.current.to_s)}
  #       }.to change(Hypothesis, :count).by 1
  #       hypothesis = Hypothesis.last
  #       expect(response).to redirect_to edit_hypothesis_path(hypothesis.id)
  #       expect(AddHypothesisToGithubContentJob.jobs.count).to eq 0
  #       expect(flash[:success]).to be_present

  #       expect(hypothesis.title).to eq simple_hypothesis_params[:title]
  #       expect(hypothesis.creator).to eq current_user
  #       expect(hypothesis.pull_request_number).to be_blank
  #       expect(hypothesis.approved_at).to be_blank
  #       expect(hypothesis.tags.count).to eq 1
  #       expect(hypothesis.tags.pluck(:title)).to eq(["economy"])

  #       expect(hypothesis.hypothesis_citations.count).to eq 1
  #       hypothesis_citation = hypothesis.hypothesis_citations.first
  #       expect(hypothesis_citation.url).to eq hc_params.values.first[:url]
  #       expect(hypothesis_citation.quotes_text).to be_present

  #       expect(hypothesis.citations.count).to eq 1
  #       citation = hypothesis.citations.first
  #       expect(citation.url).to eq hypothesis_citation.url

  #       expect(hypothesis.hypothesis_quotes.count).to eq 2
  #       hypothesis_quote1 = hypothesis.hypothesis_quotes.first
  #       hypothesis_quote2 = hypothesis.hypothesis_quotes.second
  #       expect(hypothesis_quote1.quote_text).to eq "a quote from this article"
  #       expect(hypothesis_quote1.citation_id).to eq citation.id
  #       expect(hypothesis_quote2.quote_text).to eq "and another quote from it"
  #       expect(hypothesis_quote2.citation_id).to eq citation.id
  #       expect(hypothesis_quote1.score).to be > hypothesis_quote2.score
  #     end
  #   end
  # end
end
