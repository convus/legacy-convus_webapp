# frozen_string_literal: true

require "rails_helper"

RSpec.describe "hypothesis_citations", type: :request do
  let(:base_url) { "/hypotheses/#{hypothesis.id}/citations" }
  let(:current_user) { nil }
  let!(:hypothesis) { FactoryBot.create(:hypothesis_approved, creator: FactoryBot.create(:user), created_at: Time.current - 1.hour) }
  let(:challenged_hypothesis_citation) { FactoryBot.create(:hypothesis_citation_approved, hypothesis: hypothesis) }
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
  let(:hypothesis_citation_params) do
    {
      url: citation_url,
      quotes_text: quotes_text,
      add_to_github: "0",
      citation_attributes: full_citation_params
    }
  end
  let(:challenged_params) do
    hypothesis_citation_params.merge(challenged_hypothesis_citation_id: challenged_hypothesis_citation.id,
                                     kind: "challenge_by_another_citation",
                                     challenge_description: "because it needs it")
  end

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
        expect(challenged_hypothesis_citation).to be_present
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypothesis_citations/new")
        expect(assigns(:hypothesis)&.id).to eq hypothesis.id
        expect(assigns(:challenged_hypothesis_citation)&.id).to be_blank
        expect(assigns(:hypothesis_citations_shown)&.pluck(:id)).to eq([challenged_hypothesis_citation.id])
      end
      context "challenge_citation_id" do
        it "renders with challenge" do
          get "#{base_url}/new?challenged_hypothesis_citation_id=#{challenged_hypothesis_citation.to_param}"
          expect(response.code).to eq "200"
          expect(response).to render_template("hypothesis_citations/new")
          expect(assigns(:hypothesis)&.id).to eq hypothesis.id
          expect(assigns(:challenged_hypothesis_citation)&.id).to eq challenged_hypothesis_citation.id
          expect(assigns(:challenged_hypothesis_citation)&.hypothesis_id).to eq hypothesis.id
          expect(assigns(:hypothesis_citations_shown)&.pluck(:id)).to eq([])
        end
        context "invalid challenged_hypothesis_citation_id" do
          let(:challenged_hypothesis_citation) { FactoryBot.create(:hypothesis_citation) }
          it "flash errors" do
            expect(challenged_hypothesis_citation.hypothesis_id).to_not eq hypothesis.id
            expect {
              get "#{base_url}/new?challenged_hypothesis_citation_id=#{challenged_hypothesis_citation.to_param}"
            }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe "create" do
      it "creates" do
        expect(hypothesis.hypothesis_citations.count).to eq 0
        Sidekiq::Worker.clear_all
        expect {
          post base_url, params: {hypothesis_citation: hypothesis_citation_params.except(:citation_attributes)}
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
        expect(hypothesis_citation.kind).to eq "hypothesis_supporting"

        citation = hypothesis_citation.citation
        expect(citation.creator_id).to eq current_user.id
        expect(citation.approved?).to be_falsey
        expect(citation.pull_request_number).to be_blank
        expect(citation.editable_by?(current_user)).to be_truthy
      end
      context "challenged" do
        it "creates a challenge_by_another_citation" do
          expect(challenged_hypothesis_citation).to be_present
          expect(hypothesis.reload.hypothesis_citations.count).to eq 1
          Sidekiq::Worker.clear_all
          expect {
            post base_url, params: {hypothesis_citation: challenged_params.except(:citation_attributes)}
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
          expect(hypothesis_citation.kind).to eq "challenge_by_another_citation"
          expect(hypothesis_citation.challenged_hypothesis_citation_id).to eq challenged_hypothesis_citation.id
          expect(hypothesis_citation.challenge_description).to eq "because it needs it"

          citation = hypothesis_citation.citation
          expect(citation.creator_id).to eq current_user.id
          expect(citation.approved?).to be_falsey
          expect(citation.pull_request_number).to be_blank
          expect(citation.editable_by?(current_user)).to be_truthy
        end
        context "challenge_citation_quotation" do
          let(:challenge_citation_quotation_params) do
            challenged_params.except(:citation_attributes)
              .merge(kind: "challenge_citation_quotation", url: " ")
          end
          it "creates a challenge" do
            expect(challenged_hypothesis_citation).to be_present
            expect(hypothesis.reload.hypothesis_citations.count).to eq 1
            Sidekiq::Worker.clear_all
            expect {
              post base_url, params: {hypothesis_citation: challenge_citation_quotation_params}
            }.to change(HypothesisCitation, :count).by 1
            hypothesis.reload
            expect(hypothesis.creator_id).to_not eq current_user.id
            hypothesis_citation = hypothesis.hypothesis_citations.last
            expect(response).to redirect_to edit_hypothesis_citation_path(hypothesis_id: hypothesis.id, id: hypothesis_citation.id)
            expect(AddToGithubContentJob.jobs.count).to eq 0
            expect(flash[:success]).to be_present

            expect(hypothesis_citation.approved?).to be_falsey
            expect(hypothesis_citation.creator_id).to eq current_user.id
            expect(hypothesis_citation.url).to eq challenged_hypothesis_citation.url
            expect(hypothesis_citation.quotes_text_array).to match_array(quotes)
            expect(hypothesis_citation.kind).to eq "challenge_citation_quotation"
            expect(hypothesis_citation.challenged_hypothesis_citation_id).to eq challenged_hypothesis_citation.id
            expect(hypothesis_citation.challenge_description).to eq "because it needs it"

            citation = hypothesis_citation.citation
            expect(citation.creator_id).to_not eq current_user.id
            expect(citation.approved?).to be_falsey
            expect(citation.pull_request_number).to be_blank
            expect(citation.editable_by?(current_user)).to be_falsey
          end
        end
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
        expect(assigns(:hypothesis_citations_shown)&.pluck(:id)).to eq([])
      end
      context "challenge" do
        let!(:subject) { FactoryBot.create(:hypothesis_citation_challenge_citation_quotation, challenged_hypothesis_citation: challenged_hypothesis_citation, creator: current_user) }
        it "renders" do
          expect(subject.editable_by?(current_user)).to be_truthy
          expect(subject.citation.editable_by?(current_user)).to be_falsey
          expect(subject.kind).to eq "challenge_citation_quotation"
          get "#{base_url}/#{subject.to_param}/edit"
          expect(response.code).to eq "200"
          expect(flash).to be_blank
          expect(response).to render_template("hypothesis_citations/edit")
          expect(assigns(:hypothesis_citation)&.id).to eq subject.id
          # Test that it sets the right title
          title_tag = response.body[/<title.*<\/title>/]
          expect(title_tag).to eq "<title>Edit - #{subject.citation.title}</title>"
          expect(assigns(:hypothesis_citations_shown)&.pluck(:id)).to eq([])
        end
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
      it "updates" do
        subject.reload
        expect(subject.editable_by?(current_user)).to be_truthy
        expect(hypothesis.citations.count).to eq 1
        expect(subject.quotes_text_array).to eq([])
        citation.reload
        expect(citation.title_url?).to be_truthy
        expect(citation.editable_by?(current_user)).to be_truthy
        Sidekiq::Worker.clear_all
        expect(Citation.count).to eq 1
        patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: hypothesis_citation_params}
        expect(flash[:success]).to be_present
        expect(response).to redirect_to edit_hypothesis_citation_path(hypothesis_id: hypothesis.id, id: subject.id)
        expect(assigns(:hypothesis_citation)&.id).to eq subject.id
        expect(assigns(:hypothesis_citation).submitted_to_github?).to be_falsey
        expect(AddToGithubContentJob.jobs.count).to eq 0
        subject.reload
        expect(subject.approved?).to be_falsey
        expect(subject.quotes_text_array).to eq quotes
        expect(subject.citation_id).to eq citation.id
        expect(subject.kind).to eq "hypothesis_supporting"

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
      context "challenge" do
        let!(:subject) do
          FactoryBot.create(:hypothesis_citation,
            challenged_hypothesis_citation: challenged_hypothesis_citation,
            kind: challenge_kind,
            url: citation_url,
            creator: current_user)
        end
        let(:challenge_kind) { "challenge_by_another_citation" }
        it "updates" do
          subject.reload
          expect(subject.editable_by?(current_user)).to be_truthy
          expect(hypothesis.citations.count).to eq 2
          expect(subject.challenged_hypothesis_citation&.id).to eq challenged_hypothesis_citation.id
          expect(subject.quotes_text_array).to eq([])
          citation.reload
          expect(citation.title_url?).to be_truthy
          expect(citation.editable_by?(current_user)).to be_truthy
          Sidekiq::Worker.clear_all
          expect(Citation.count).to eq 2
          patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: challenged_params}
          expect(flash[:success]).to be_present
          expect(response).to redirect_to edit_hypothesis_citation_path(hypothesis_id: hypothesis.id, id: subject.id)
          expect(assigns(:hypothesis_citation)&.id).to eq subject.id
          expect(assigns(:hypothesis_citation).submitted_to_github?).to be_falsey
          expect(AddToGithubContentJob.jobs.count).to eq 0
          subject.reload
          expect(subject.approved?).to be_falsey
          expect(subject.quotes_text_array).to eq quotes
          expect(subject.citation_id).to eq citation.id
          expect(subject.kind).to eq "challenge_by_another_citation"
          expect(subject.challenged_hypothesis_citation_id).to eq challenged_hypothesis_citation.id
          expect(subject.challenge_description).to eq "because it needs it"

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
        context "challenge_citation_quotation" do
          let(:challenge_kind) { "challenge_citation_quotation" }
          it "updates, does not update blocked attrs" do
            subject.reload
            expect(subject.url).to_not eq citation_url
            expect(subject.url).to eq challenged_hypothesis_citation.url
            expect(subject.editable_by?(current_user)).to be_truthy
            expect(hypothesis.citations.count).to eq 2
            expect(subject.quotes_text_array).to eq([])
            citation.reload
            expect(citation.editable_by?(current_user)).to be_falsey
            Sidekiq::Worker.clear_all
            expect(Citation.count).to eq 1
            # Note: using the default challenged params - which has a different kind
            patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: challenged_params.merge(challenged_hypothesis_citation_id: 21222)}
            expect(flash[:success]).to be_present
            expect(response).to redirect_to edit_hypothesis_citation_path(hypothesis_id: hypothesis.id, id: subject.id)
            expect(assigns(:hypothesis_citation)&.id).to eq subject.id
            expect(assigns(:hypothesis_citation).submitted_to_github?).to be_falsey
            expect(AddToGithubContentJob.jobs.count).to eq 0
            subject.reload
            expect(subject.approved?).to be_falsey
            expect(subject.quotes_text_array).to eq quotes
            expect(subject.challenged_hypothesis_citation_id).to eq challenged_hypothesis_citation.id
            expect(subject.citation_id).to eq challenged_hypothesis_citation.citation_id
            expect(subject.kind).to eq challenge_kind

            citation.reload
            expect(citation.title).to_not eq full_citation_params[:title] # Because it shouldn't have been updated
          end
        end
      end
      context "citation already created" do
        let!(:citation) { FactoryBot.create(:citation_approved, url: citation_url) }
        it "doesn't update blocked attributes" do
          subject.reload
          expect(subject.editable_by?(current_user)).to be_truthy
          expect(hypothesis.citations.count).to eq 1
          expect(subject.quotes_text_array).to eq([])
          citation.reload
          expect(citation.editable_by?(current_user)).to be_falsey
          Sidekiq::Worker.clear_all
          expect(Citation.count).to eq 1
          patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: hypothesis_citation_params}
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
          expect(citation.title).to_not eq full_citation_params[:title] # Because it shouldn't have been updated
        end
        context "not passing citation attributes" do
          it "updates without error" do # We aren't passing the citations hash, make sure it doesn't explode
            subject.reload
            expect(subject.editable_by?(current_user)).to be_truthy
            citation.reload
            expect(citation.editable_by?(current_user)).to be_falsey
            patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: hypothesis_citation_params.except(:citation_attributes)}
            expect(flash[:success]).to be_present
            expect(response).to redirect_to edit_hypothesis_citation_path(hypothesis_id: hypothesis.id, id: subject.id)
            expect(assigns(:hypothesis_citation)&.id).to eq subject.id
            expect(AddToGithubContentJob.jobs.count).to eq 0
            subject.reload
            expect(subject.approved?).to be_falsey
            expect(subject.quotes_text_array).to eq quotes
            expect(subject.citation_id).to eq citation.id
            citation.reload
            expect(citation.title).to_not eq full_citation_params[:title] # Because it shouldn't have been updated
          end
        end
      end
      context "failing citation update" do
        # NOTE: I don't actually know how to get the citation to error in update
        # so this stubs the error, just in case it can happen
        it "renders edit with flash error" do
          subject.reload
          expect_any_instance_of(Citation).to receive(:update) { |c| c.errors.add(:base, "CRAY error") && false }
          patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: hypothesis_citation_params}
          expect(flash[:error]).to match(/CRAY error/)
          expect(response).to render_template("hypothesis_citations/edit")
        end
      end
      context "add to github" do
        let(:update_add_to_github_params) { hypothesis_citation_params.merge(add_to_github: true) }
        it "enqueues the job" do
          subject.reload
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.id}", params: {hypothesis_citation: update_add_to_github_params}
          expect(flash[:success]).to be_present
          expect(response).to redirect_to hypothesis_path(hypothesis.to_param)
          expect(assigns(:hypothesis_citation)&.id).to eq subject.id
          expect(AddToGithubContentJob.jobs.count).to eq 1
          expect(AddToGithubContentJob.jobs.map { |j| j["args"] }.last.flatten).to eq(["HypothesisCitation", subject.id])
        end

        it "actually runs" do
          subject.reload
          citation.update(approved_at: Time.current - 1.hour) # Test adding a hypothesis_citation with an existing citation
          VCR.use_cassette("hypotheses_citation_controller-create_skip_citation", match_requests_on: [:method]) do
            expect(Hypothesis.count).to eq 1
            expect(Citation.count).to eq 1
            expect(citation.pull_request_number).to be_blank
            expect(citation.approved?).to be_truthy
            Sidekiq::Worker.clear_all
            Sidekiq::Testing.inline! do
              patch "#{base_url}/#{subject.to_param}", params: {
                hypothesis_citation: update_add_to_github_params.merge(initially_toggled: true)
              }
            end
            expect(response).to redirect_to hypothesis_path(hypothesis.to_param)
            expect(flash[:success]).to be_present

            hypothesis.reload
            expect(hypothesis.citations.count).to eq 1
            expect(hypothesis.approved?).to be_truthy
            expect(hypothesis.pull_request_number).to be_blank
            # Even though passed new information, it doesn't update the existing citation
            citation.reload
            expect(citation.pull_request_number).to be_blank

            subject.reload
            expect(subject.pull_request_number).to be_present
          end
        end
      end
    end
  end
end
