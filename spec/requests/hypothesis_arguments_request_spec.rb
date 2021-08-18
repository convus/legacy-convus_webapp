# frozen_string_literal: true

require "rails_helper"

RSpec.describe "hypothesis_arguments", type: :request do
  let(:base_url) { "/hypotheses/#{hypothesis.id}/arguments" }
  let(:current_user) { nil }
  let!(:hypothesis) { FactoryBot.create(:hypothesis_approved, creator: FactoryBot.create(:user), created_at: Time.current - 1.hour) }
  let(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: citation_url, creator: current_user) }
  let(:citation) { hypothesis_citation.citation }
  let(:quote) { }
  let(:subject) { FactoryBot.create(:argument, hypothesis: hypothesis, creator: current_user) }

  let(:full_argument_params) do
    {
      text: "This is the text of an argument on something cool.\n\nAnd this is the text of the seconnd section",
    }
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
          post base_url, params: {argument: full_argument_params}
        }.to change(Argument, :count).by 1
        hypothesis.reload
        expect(hypothesis.creator_id).to_not eq current_user.id
        argument = hypothesis.arguments.last
        expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.id, id: argument.id)
        expect(AddToGithubContentJob.jobs.count).to eq 0
        expect(flash[:success]).to be_present

        expect(argument.approved?).to be_falsey
        expect(argument.creator_id).to eq current_user.id
        expect(argument.text).to eq full_argument_params[:text]
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
        expect(title_tag).to eq "<title>Edit - #{subject.display_id}</title>"
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
        expect(subject.text).to_not eq full_argument_params[:text]
        Sidekiq::Worker.clear_all
        patch "#{base_url}/#{subject.id}", params: {argument: full_argument_params}
        expect(flash[:success]).to be_present
        expect(response).to redirect_to edit_hypothesis_argument_path(hypothesis_id: hypothesis.id, id: subject.id)
        expect(assigns(:argument)&.id).to eq subject.id
        expect(AddToGithubContentJob.jobs.count).to eq 0
        subject.reload
        expect(subject.approved?).to be_falsey
        expect(subject.text).to eq full_argument_params[:text]
      end
      context "failing update" do
        # NOTE: I don't actually know how to get the argument to error in update
        # so this stubs the error, just in case it can happen
        it "renders edit" do
          subject.reload
          expect_any_instance_of(Argument).to receive(:update) { |c| c.errors.add(:base, "CRAY error") && false }
          patch "#{base_url}/#{subject.id}", params: {argument: full_argument_params}
          expect(flash[:error]).to be_blank
          expect(assigns(:argument).errors.full_messages.to_s).to match(/CRAY error/)
          expect(response).to render_template("hypothesis_arguments/edit")
        end
      end
      context "add to github" do
        let(:update_add_to_github_params) { full_argument_params.merge(add_to_github: true) }
        it "enqueues the job" do
          subject.reload
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.id}", params: {argument: update_add_to_github_params}
          expect(flash[:success]).to be_present
          expect(response).to redirect_to hypothesis_path(hypothesis.to_param, argument_id: subject.id)
          expect(assigns(:argument)&.id).to eq subject.id
          expect(AddToGithubContentJob.jobs.count).to eq 1
          expect(AddToGithubContentJob.jobs.map { |j| j["args"] }.last.flatten).to eq(["Argument", subject.id])
        end
      end
    end
  end
end
