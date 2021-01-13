# frozen_string_literal: true

require "rails_helper"

RSpec.describe "hypothesis_citations", type: :request do
  let(:base_url) { "/hypotheses/#{hypothesis.id}/citations" }
  let(:current_user) { nil }
  let!(:hypothesis) { FactoryBot.create(:hypothesis_approved, creator: FactoryBot.create(:user)) }
  let(:subject) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: citation_url, creator: current_user) }
  let(:citation) { subject.citation }

  let(:full_citation_params) do
    {
      title: "A meta-analysis of biological impacts of artificial light at night",
      publication_title: "Nature",
      kind: "research_meta_analysis",
      peer_reviewed: true,
      randomized_controlled_trial: false,
      url_is_direct_link_to_full_text: "0",
      authors_str: "Dirk Sanders\n\nEnric Frago\n Rachel Kehoe\nChristophe Patterson\n\n\n  Kevin J. Gaston ",
      published_date_str: "2020-11-2",
      url_is_not_publisher: false
    }
  end
  let(:citation_url) { "https://www.nature.com/articles/s41559-020-01322-x" }
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
        expect(hypothesis.creator_id).to_not eq current_user.id
        hypothesis_citation = hypothesis.hypothesis_citations.last
        expect(response).to redirect_to edit_hypothesis_citation_path(hypothesis_id: hypothesis.id, id: hypothesis_citation.id)
        expect(AddToGithubContentJob.jobs.count).to eq 0
        expect(flash[:success]).to be_present

        expect(hypothesis_citation.approved?).to be_falsey
        expect(hypothesis_citation.creator_id).to eq current_user.id
        expect(hypothesis_citation.url).to eq citation_url
        expect(hypothesis_citation.quotes_text_array).to match_array(quotes)

        citation = hypothesis_citation.citation
        expect(citation.creator_id).to eq current_user.id
        expect(citation.approved?).to be_falsey
        expect(citation.pull_request_number).to be_blank
        expect(citation.editable_by?(current_user)).to be_truthy
      end
    end

    describe "edit" do
      it "renders" do
        expect(subject.editable_by?(current_user)).to be_truthy
        expect(subject.citation.editable_by?(current_user)).to be_truthy
        get "#{base_url}/#{subject.to_param}/edit"
        expect(response.code).to eq "200"
        expect(flash).to be_blank
        expect(response).to render_template("hypothesis_citations/edit")
        expect(assigns(:hypothesis_citation)&.id).to eq subject.id
        # Test that it sets the right title
        title_tag = response.body[/<title.*<\/title>/]
        expect(title_tag).to eq "<title>Edit - #{subject.citation.title}</title>"
      end
      context "approved" do
        let(:subject) { FactoryBot.create(:hypothesis_citation_approved, hypothesis: hypothesis, creator: current_user) }
        it "redirects" do
          expect(subject.creator_id).to eq current_user.id
          expect(subject.editable_by?(current_user)).to be_falsey
          get "#{base_url}/#{subject.to_param}/edit"
          expect(response.code).to redirect_to hypothesis_path(hypothesis.to_param)
          expect(flash[:error]).to be_present
        end
      end
      context "other users" do
        let(:subject) { FactoryBot.create(:hypothesis_citation_approved, hypothesis: hypothesis, creator: hypothesis.creator) }
        it "redirects" do
          expect(subject.creator_id).to_not eq current_user.id
          expect(subject.editable_by?(current_user)).to be_falsey
          get "#{base_url}/#{subject.to_param}/edit"
          expect(response.code).to redirect_to hypothesis_path(hypothesis.to_param)
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "update" do
      let(:hypothesis_citation_update_params) { {url: citation_url, quotes_text: quotes_text, citation_attributes: full_citation_params} }
      let(:authors_array) { ["Dirk Sanders", "Enric Frago", "Rachel Kehoe", "Christophe Patterson", "Kevin J. Gaston"] }
      it "updates" do
        subject.reload
        expect(subject.editable_by?(current_user)).to be_truthy
        expect(hypothesis.citations.count).to eq 1
        expect(subject.quotes_text_array).to eq([])
        citation.reload
        expect(citation.title_url?).to be_truthy
        Sidekiq::Worker.clear_all
        expect(Citation.count).to eq 1
        patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: hypothesis_citation_update_params}
        expect(flash[:success]).to be_present
        expect(response).to redirect_to edit_hypothesis_citation_path(hypothesis_id: hypothesis.id, id: subject.id)
        expect(assigns(:hypothesis_citation)&.id).to eq subject.id
        expect(assigns(:hypothesis_citation).submitted_to_github?).to be_falsey
        expect(AddToGithubContentJob.jobs.count).to eq 0
        subject.reload
        expect(subject.approved?).to be_falsey
        expect(subject.quotes_text_array).to eq quotes
        expect(subject.citation_id).to eq citation.id

        citation.reload
        expect(citation.title).to eq full_citation_params[:title]
        expect(citation.url).to eq citation_url
        expect(citation.submitted_to_github?).to be_falsey
        expect(citation.publication).to be_present
        expect(citation.publication_title).to eq "Nature"
        expect(citation.authors).to eq ["Dirk Sanders", "Enric Frago", "Rachel Kehoe", "Christophe Patterson", "Kevin J. Gaston"]
        expect(citation.published_date_str).to eq "2020-11-02"
        expect(citation.url_is_direct_link_to_full_text).to be_falsey
        expect(citation.creator_id).to eq current_user.id
        expect(citation.kind).to eq full_citation_params[:kind]
      end
      context "failing citation update" do
        # NOTE: I don't actually know how to get the citation to error in update
        # so this stubs the error, just in case it can happen
        it "renders edit with flash error" do
          subject.reload
          expect_any_instance_of(Citation).to receive(:update) { |c| c.errors.add(:base, "CRAY error") && false }
          patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: hypothesis_citation_update_params}
          expect(flash[:error]).to match(/CRAY error/)
          expect(response).to render_template("hypothesis_citations/edit")
        end
      end
    end
  end
end
