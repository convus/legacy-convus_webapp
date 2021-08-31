# frozen_string_literal: true

require "rails_helper"

RSpec.describe "hypothesis_arguments", type: :request do
  let(:base_url) { "/hypotheses/#{hypothesis.ref_id}/arguments" }
  let(:current_user) { nil }
  let!(:hypothesis) { FactoryBot.create(:hypothesis, creator: hypothesis_creator, created_at: Time.current - 1.hour) }
  let(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: citation_url, creator: current_user) }
  let(:hypothesis_creator) { FactoryBot.create(:user) }
  let(:citation) { hypothesis_citation.citation }
  let(:quote) {}
  let(:subject) { FactoryBot.create(:argument, hypothesis: hypothesis, creator: current_user) }

  let(:simple_argument_params) do
    {
      text: "This is the text of an argument on something cool.\n\nAnd this is the text of the seconnd section"
    }
  end
  let(:text) { "\nThis is the text\n\n> This is a quote\n\nAnd some more text" }
  let(:argument_with_quote_params) do
    {
      text: text,
      argument_quotes_attributes: argument_quotes_params
    }
  end
  let(:argument_quotes_params) do
    {Time.current.to_i.to_s => {
      url: "https://example.com/something-of-interest",
      text: "This is a quote",
      ref_number: 0
    }}
  end
  let(:citation_params) do
    {
      url: "https://www.nature.com/articles/s41559-020-01322-x",
      title: "A meta-analysis of biological impacts of artificial light at night",
      publication_title: "Nature",
      kind: "research_meta_analysis",
      doi: "https://doi.org/10.1038/s41559-020-01322-x",
      peer_reviewed: true,
      randomized_controlled_trial: false,
      url_is_direct_link_to_full_text: "0",
      authors_str: "Dirk Sanders\n\nEnric Frago\n Rachel Kehoe\nChristophe Patterson\n\n\n  Kevin J. Gaston ",
      published_date_str: "2020-11-2",
      url_is_not_publisher: false
    }
  end

  def expect_argument_with_quotes_to_be_updated(argument, target_url: "https://example.com/something-of-interest")
    expect(assigns(:argument)&.id).to eq argument.id
    argument.reload
    expect(argument.approved?).to be_falsey
    expect(argument.text).to eq argument_with_quote_params[:text]
    expect(argument.argument_quotes.count).to eq 1
    argument_quote = argument.argument_quotes.first
    expect(argument_quote.text).to eq "This is a quote"
    expect(argument_quote.url).to eq target_url
    expect(argument_quote.ref_number).to eq 0
    expect(argument_quote.creator_id).to eq current_user.id
    expect(argument_quote.citation).to be_present if target_url.present?
    argument_quote
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
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypothesis_arguments/new")
        expect(assigns(:hypothesis)&.id).to eq hypothesis.id
        expect(assigns(:argumennt)&.id).to be_blank
      end
    end

    describe "create" do
      it "creates" do
        expect(hypothesis.arguments.count).to eq 0
        Sidekiq::Worker.clear_all
        expect {
          post base_url, params: {argument: simple_argument_params}
        }.to change(Argument, :count).by 1
        hypothesis.reload
        expect(hypothesis.creator_id).to_not eq current_user.id
        argument = hypothesis.arguments.last
        expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: argument.id)
        expect(AddToGithubContentJob.jobs.count).to eq 0
        expect(flash[:success]).to be_present

        expect(argument.approved?).to be_falsey
        expect(argument.creator_id).to eq current_user.id
        expect(argument.text).to eq simple_argument_params[:text]
        expect(argument.body_html).to be_present
      end
      context "with argument_quotes" do
        it "creates" do
          expect(hypothesis.reload.editable_by?(current_user)).to be_falsey
          expect(hypothesis.arguments.count).to eq 0
          Sidekiq::Worker.clear_all
          expect {
            post base_url, params: {argument: argument_with_quote_params,
                                    hypothesis_title: "new title", hypothesis_tags_string: "animals, Something of Interest"}
          }.to change(Argument, :count).by 1
          hypothesis.reload
          expect(hypothesis.creator_id).to_not eq current_user.id
          argument = hypothesis.arguments.last
          expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: argument.id)
          expect(AddToGithubContentJob.jobs.count).to eq 0
          expect(flash[:success]).to be_present
          expect_argument_with_quotes_to_be_updated(argument)
          hypothesis.reload
          expect(hypothesis.title).to_not eq "new title"
          expect(hypothesis.tags.pluck(:title)).to eq([])
        end
        context "with hypothesis params" do
          let(:hypothesis_creator) { current_user }
          it "updates hypothesis" do
            expect(hypothesis.reload.editable_by?(current_user)).to be_truthy
            expect(hypothesis.arguments.count).to eq 0
            Sidekiq::Worker.clear_all
            expect {
              post base_url, params: {argument: argument_with_quote_params,
                                      hypothesis_title: "new title", hypothesis_tags_string: "animals, Something of Interest"}
            }.to change(Argument, :count).by 1
            hypothesis.reload
            argument = hypothesis.arguments.last
            expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: argument.id)
            expect(AddToGithubContentJob.jobs.count).to eq 0
            expect(flash[:success]).to be_present
            expect(argument.creator_id).to eq current_user.id
            expect_argument_with_quotes_to_be_updated(argument)

            hypothesis.reload
            expect(hypothesis.title).to eq "new title"
            expect(hypothesis.tags.pluck(:title)).to eq(["animals", "Something of Interest"])
          end
        end
      end
    end

    describe "edit" do
      it "renders" do
        expect(subject.editable_by?(current_user)).to be_truthy
        get "#{base_url}/#{subject.to_param}/edit"
        expect(response.code).to eq "200"
        expect(flash).to be_blank
        expect(response).to render_template("hypothesis_arguments/edit")
        expect(assigns(:argument)&.id).to eq subject.id
        # Test that it sets the right title
        title_tag = response.body[/<title.*<\/title>/]
        expect(title_tag).to eq "<title>Edit Argument: #{subject.hypothesis.title}</title>"
        expect(assigns(:hypothesis_citations_shown)&.pluck(:id)).to eq([])
      end
      context "approved" do
        let(:subject) { FactoryBot.create(:argument_approved, hypothesis: hypothesis, creator: current_user) }
        it "redirects" do
          expect(subject.creator_id).to eq current_user.id
          expect(subject.editable_by?(current_user)).to be_falsey
          get "#{base_url}/#{subject.to_param}/edit"
          expect(response.code).to redirect_to hypothesis_path(hypothesis.to_param)
          expect(flash[:error]).to be_present
        end
      end
      context "other users" do
        let(:subject) { FactoryBot.create(:argument, hypothesis: hypothesis, creator: hypothesis.creator) }
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
        expect(subject.text).to_not eq argument_with_quote_params[:text]
        expect(subject.argument_quotes.count).to eq 0
        Sidekiq::Worker.clear_all
        patch "#{base_url}/#{subject.id}", params: {argument: argument_with_quote_params}
        expect(flash[:success]).to be_present
        expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: subject.id)
        expect_argument_with_quotes_to_be_updated(subject)
        expect(AddToGithubContentJob.jobs.count).to eq 0
      end
      context "with citation params" do
        let(:argument_with_citation_params) do
          {
            text: text,
            argument_quotes_attributes: {
              Time.current.to_i.to_s => {
                url: citation_params[:url],
                text: "This is a quote",
                ref_number: 0
              }
            },
            citations_attributes: {Time.current.to_i.to_s => citation_params}
          }
        end
        def expect_citation_to_be_updated(citation)
          expect(Citation.count).to eq 1
          expect(citation.editable_by?(current_user)).to be_truthy
          expect(citation.authors).to eq(["Dirk Sanders", "Enric Frago", "Rachel Kehoe", "Christophe Patterson", "Kevin J. Gaston"])
          expect_attrs_to_match_hash(citation, citation_params.except(:authors_str, :published_date_str, :url_is_direct_link_to_full_text))
          expect(citation.published_date_str).to eq "2020-11-02"
          expect(citation.url_is_direct_link_to_full_text).to be_falsey
        end
        it "creates the citation" do
          subject.reload
          expect(subject.editable_by?(current_user)).to be_truthy
          expect(subject.text).to_not eq argument_with_citation_params[:text]
          expect(subject.argument_quotes.count).to eq 0
          expect(Citation.count).to eq 0
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.id}", params: {argument: argument_with_citation_params}
          expect(flash[:success]).to be_present
          expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: subject.id)
          argument_quote = expect_argument_with_quotes_to_be_updated(subject, target_url: citation_params[:url])
          expect_citation_to_be_updated(argument_quote.citation)
        end
        context "citation already exists, not editable_by current_user" do
          let!(:citation) { Citation.create(url: citation_params[:url], creator: current_user) }
          it "updates" do
            subject.reload
            expect(subject.editable_by?(current_user)).to be_truthy
            expect(subject.text).to_not eq argument_with_citation_params[:text]
            expect(subject.argument_quotes.count).to eq 0
            expect(citation.reload.editable_by?(current_user)).to be_truthy
            Sidekiq::Worker.clear_all
            patch "#{base_url}/#{subject.id}", params: {argument: argument_with_citation_params}
            expect(flash[:success]).to be_present
            expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: subject.id)
            expect_argument_with_quotes_to_be_updated(subject, target_url: citation_params[:url])
            expect(Citation.count).to eq 1
            citation.reload
            expect_citation_to_be_updated(citation)
          end
        end
        context "citation already exists, not editable_by current_user" do
          let!(:citation) { Citation.find_or_create_by_params(url: citation_params[:url]) }
          it "does not update" do
            subject.reload
            expect(subject.editable_by?(current_user)).to be_truthy
            expect(subject.text).to_not eq argument_with_citation_params[:text]
            expect(subject.argument_quotes.count).to eq 0
            expect(citation.reload.editable_by?(current_user)).to be_falsey
            Sidekiq::Worker.clear_all
            patch "#{base_url}/#{subject.id}", params: {argument: argument_with_citation_params}
            expect(flash[:success]).to be_present
            expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: subject.id)
            argument_quote = expect_argument_with_quotes_to_be_updated(subject, target_url: citation_params[:url])
            citation = argument_quote.citation
            expect(Citation.count).to eq 1
            expect(citation.editable_by?(current_user)).to be_falsey
            expect(citation.authors).to be_blank
          end
        end
      end
      context "with existing argument_quotes" do
        let(:text) { "\nThis is the text\n\n> This is a quote\n\nAnd some more text\n > And another quote" }
        let!(:argument_quote1) { FactoryBot.create(:argument_quote, argument: subject, creator: current_user) }
        let!(:argument_quote2) { FactoryBot.create(:argument_quote, argument: subject, creator: current_user) }
        # NOTE: argument_quote0 is removed because it isn't included in params - if a quote gets removed from the frontend, it needs to drop
        let!(:argument_quote0) { FactoryBot.create(:argument_quote, argument: subject, creator: current_user) }
        let(:argument_quotes_params) do
          {
            argument_quote1.id.to_s => {
              url: "https://example.com/a-different-url",
              text: "And another quote",
              id: argument_quote1.id,
              removed: false,
              ref_number: 2
            }, argument_quote2.id.to_s => {
              url: "",
              text: "Something that is removed",
              id: argument_quote2.id,
              removed: true,
              ref_number: 3
            }, (Time.current.to_i - 5).to_s => {
              url: "https://something.com",
              text: "This is a removed quote",
              removed: true,
              ref_number: 4
            }, Time.current.to_i.to_s => {
              url: "",
              text: "This is a quote",
              removed: false,
              ref_number: 0
            }
          }
        end
        it "updates" do
          subject.reload
          expect(subject.editable_by?(current_user)).to be_truthy
          expect(subject.text).to_not eq text
          expect(subject.argument_quotes.count).to eq 3
          expect(ArgumentQuote.pluck(:id)).to match_array([argument_quote0.id, argument_quote1.id, argument_quote2.id])

          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.id}", params: {argument: argument_with_quote_params}
          expect(flash[:success]).to be_present
          expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: subject.id)
          expect(assigns(:argument)&.id).to eq subject.id
          expect(AddToGithubContentJob.jobs.count).to eq 0
          subject.reload
          expect(subject.approved?).to be_falsey
          expect(subject.body_html).to be_present
          expect(subject.text).to eq argument_with_quote_params[:text]

          argument_quote1.reload
          expect(argument_quote1.text).to eq "And another quote"
          expect(argument_quote1.url).to eq "https://example.com/a-different-url"
          expect(argument_quote1.removed).to be_falsey
          expect(argument_quote1.ref_number).to eq 2
          expect(argument_quote1.creator_id).to eq current_user.id

          argument_quote3 = subject.argument_quotes.where(ref_number: 0).first
          expect(argument_quote3.text).to eq "This is a quote"
          expect(argument_quote3.url).to eq nil
          expect(argument_quote3.removed).to be_falsey
          expect(argument_quote3.creator_id).to eq current_user.id

          argument_quote4 = subject.argument_quotes.where(ref_number: 4).first
          expect(argument_quote4.text).to eq "This is a removed quote"
          expect(argument_quote4.url).to eq "https://something.com"
          expect(argument_quote4.removed).to be_truthy
          expect(argument_quote4.creator_id).to eq current_user.id

          # Because argument_quote0 and argument_quote2 is gone
          expect(subject.argument_quotes.pluck(:id)).to match_array([argument_quote1.id, argument_quote3.id, argument_quote4.id])
          expect(ArgumentQuote.where(id: argument_quote2.id).any?).to be_falsey
        end
      end
      context "update hypothesis" do
        let(:hypothesis_creator) { current_user }
        it "updates" do
          subject.reload
          expect(subject.editable_by?(current_user)).to be_truthy
          expect(subject.text).to_not eq argument_with_quote_params[:text]
          expect(subject.argument_quotes.count).to eq 0
          hypothesis.update(tags_string: "Economy")
          expect(hypothesis.reload.editable_by?(current_user)).to be_truthy
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.id}", params: {argument: argument_with_quote_params,
                                                      hypothesis_title: "This seems like the truth",
                                                      hypothesis_tags_string: "economy\nparties"}
          expect(flash[:success]).to be_present
          expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: subject.id)
          expect(AddToGithubContentJob.jobs.count).to eq 0
          expect_argument_with_quotes_to_be_updated(subject)
          expect(subject.approved?).to be_falsey

          expect(hypothesis.reload.title).to eq "This seems like the truth"
          expect(hypothesis.tags.pluck(:title)).to eq(["Economy", "parties"])
        end
        context "hypothesis can't be updated" do
          let(:hypothesis) { FactoryBot.create(:hypothesis_approved, creator: current_user, created_at: Time.current - 1.hour, title: "Original hypothesis title") }
          it "does not update" do
            subject.reload
            expect(subject.editable_by?(current_user)).to be_truthy
            expect(subject.text).to_not eq argument_with_quote_params[:text]
            expect(subject.argument_quotes.count).to eq 0
            hypothesis.update(tags_string: "Economy")
            expect(hypothesis.reload.editable_by?(current_user)).to be_falsey
            Sidekiq::Worker.clear_all
            patch "#{base_url}/#{subject.id}", params: {argument: argument_with_quote_params,
                                                        hypothesis_title: "This seems like the truth",
                                                        hypothesis_tags_string: "economy\nparties"}
            expect(flash[:success]).to be_present
            expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: subject.id)
            expect(AddToGithubContentJob.jobs.count).to eq 0
            expect_argument_with_quotes_to_be_updated(subject)
            expect(subject.approved?).to be_falsey

            expect(hypothesis.reload.title).to eq "Original hypothesis title"
            expect(hypothesis.tags.pluck(:title)).to eq(["Economy"])
          end
        end
      end
      context "failing update" do
        # NOTE: I don't actually know how to get the argument to error in update
        # so this stubs the error, just in case it can happen
        it "renders edit" do
          subject.reload
          expect_any_instance_of(Argument).to receive(:update) { |c| c.errors.add(:base, "CRAY error") && false }
          patch "#{base_url}/#{subject.id}", params: {argument: simple_argument_params}
          expect(flash[:error]).to be_blank
          expect(assigns(:argument).errors.full_messages.to_s).to match(/CRAY error/)
          expect(response).to render_template("hypothesis_arguments/edit")
        end
        context "already submitted" do
          let(:subject) { FactoryBot.create(:argument_approved, hypothesis: hypothesis, creator: current_user, text: "Original argument text") }
          it "redirects to edit" do
            expect(subject.reload.editable_by?(current_user)).to be_falsey
            patch "#{base_url}/#{subject.id}", params: {argument: simple_argument_params}
            expect(flash[:error]).to be_present
            expect(response).to redirect_to(hypothesis_path(hypothesis.to_param))
            expect(subject.reload.text).to eq "Original argument text"
          end
        end
      end
      context "add to github" do
        let(:update_add_to_github_params) { argument_with_quote_params.merge(add_to_github: true) }
        it "enqueues the job" do
          subject.reload
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.id}", params: {argument: update_add_to_github_params}
          expect(flash[:success]).to be_present
          expect(response).to redirect_to hypothesis_path(hypothesis.ref_id, argument_id: subject.ref_number)
          expect(assigns(:argument)&.id).to eq subject.id
          expect(AddToGithubContentJob.jobs.count).to eq 1
          expect(AddToGithubContentJob.jobs.map { |j| j["args"] }.last.flatten).to eq(["Argument", subject.id])
          expect_argument_with_quotes_to_be_updated(subject)
          expect(subject.approved?).to be_falsey
        end
        context "blank URL" do
          let(:hypothesis_creator) { current_user }
          let(:argument_params) do
            {
              add_to_github: "1",
              text: "\nThis is the text\n\n> This is a quote\n\nAnd some more text",
              argument_quotes_attributes: {
                Time.current.to_i.to_s => {
                  url: " ",
                  text: "This is a quote",
                  ref_number: 0
                }
              }
            }
          end
          it "doesn't add_to_github" do
            subject.reload
            Sidekiq::Worker.clear_all
            hypothesis.update(tags_string: "Economy")
            expect(hypothesis.reload.tags.pluck(:title)).to eq(["Economy"])
            expect(hypothesis.editable_by?(current_user)).to be_truthy
            patch "#{base_url}/#{subject.id}", params: {
              argument: argument_params,
              hypothesis_title: "Some new title",
              hypothesis_tags_string: "some new tag, economy"
            }
            expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.ref_id, id: subject.id)
            expect_argument_with_quotes_to_be_updated(subject, target_url: nil)
            expect(subject.approved?).to be_falsey
            expect(flash[:error]).to match(/url/i)
            expect(AddToGithubContentJob.jobs.count).to eq 0

            expect(hypothesis.reload.title).to eq "Some new title"
            expect(hypothesis.reload.tags.pluck(:title)).to match_array(["some new tag", "Economy"])
          end
        end
      end
    end
  end
end
