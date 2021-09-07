require "rails_helper"

RSpec.describe PreviousTitle, type: :model do
  describe "creation" do
    before { Sidekiq::Worker.clear_all }
    let(:hypothesis_title) { "some weird title." }
    let(:hypothesis_title2) { "some new weird title." }
    let(:hypothesis) { FactoryBot.create(:hypothesis, title: hypothesis_title) }
    it "does not create on change" do
      expect(hypothesis.approved?).to be_falsey
      expect {
        hypothesis.update(title: hypothesis_title2)
        StorePreviousHypothesisTitleJob.drain
      }.to_not change(PreviousTitle, :count)
    end
    context "approved" do
      let(:hypothesis) { FactoryBot.create(:hypothesis_approved, title: hypothesis_title) }
      it "creates" do
        expect(hypothesis.approved?).to be_truthy
        expect {
          hypothesis.update(title: hypothesis_title2)
          StorePreviousHypothesisTitleJob.drain
        }.to change(PreviousTitle, :count).by 1
        hypothesis.reload
        expect(hypothesis.title).to eq hypothesis_title2
        expect(hypothesis.previous_titles.pluck(:title)).to eq([hypothesis_title])
        expect(Hypothesis.friendly_find(hypothesis_title)&.id).to eq hypothesis.id
      end
      context "title change without case change" do
        it "does not create" do
          hypothesis.reload
          expect {
            hypothesis.update(title: "Some-WEIRD title.")
            expect {
              StorePreviousHypothesisTitleJob.drain
            }.to raise_error(/title/i)
          }.to_not change(PreviousTitle, :count)
          hypothesis.reload
          expect(hypothesis.title).to eq "Some-WEIRD title." # Sanity check that it did actually change
        end
      end
      context "duplicated previous title" do
        let(:hypothesis2_title) { "another title to something." }
        let(:hypothesis2) { FactoryBot.create(:hypothesis_approved, title: hypothesis2_title) }
        it "permits creation" do
          hypothesis.update(title: hypothesis_title2)
          expect(hypothesis2.update(title: hypothesis_title)).to be_truthy
          StorePreviousHypothesisTitleJob.drain
          expect(hypothesis.previous_titles.pluck(:title)).to eq([hypothesis_title])
          expect(hypothesis2.previous_titles.pluck(:title)).to eq([hypothesis2_title])
          # It finds the current hypothesis with the title
          expect(Hypothesis.friendly_find(hypothesis_title)&.id).to eq hypothesis2.id
          expect(hypothesis2.title).to eq hypothesis_title
          hypothesis2.update(title: "another title.")
          StorePreviousHypothesisTitleJob.drain
          expect(hypothesis2.previous_titles.pluck(:title)).to match_array([hypothesis_title, hypothesis2_title])
          # It finds the hypothesis with the most recent title
          expect(Hypothesis.friendly_find(hypothesis_title)&.id).to eq hypothesis2.id
          # And then we switch back
          hypothesis.update(title: "Some WEIRD title.")
          StorePreviousHypothesisTitleJob.drain
          expect(hypothesis.previous_titles.pluck(:title)).to match_array([hypothesis_title, hypothesis_title2])
          expect(Hypothesis.friendly_find(hypothesis_title)&.id).to eq hypothesis.id
          # Because we find the most recent with the matching title, permit duplicated previous_titles with the same title
          hypothesis.update(title: "a final title.")
          StorePreviousHypothesisTitleJob.drain
          expect(hypothesis.previous_titles.pluck(:title)).to match_array([hypothesis_title, "Some WEIRD title.", hypothesis_title2])
          expect(hypothesis.previous_titles.pluck(:slug)).to match_array(["some-weird-title", "some-weird-title", "some-new-weird-title"])
          expect(PreviousTitle.friendly_matching(hypothesis_title).pluck(:hypothesis_id)).to match_array([hypothesis2.id, hypothesis.id, hypothesis.id])
          expect(Hypothesis.friendly_find(hypothesis_title)&.id).to eq hypothesis.id
          # Finally, make sure that failed updates don't create extra titles
          expect(hypothesis2.update(title: "a final title")).to be_falsey
          StorePreviousHypothesisTitleJob.drain
          hypothesis2.reload
          expect(hypothesis2.title).to eq "another title"
          expect(hypothesis2.previous_titles.pluck(:title)).to match_array([hypothesis_title, hypothesis2_title])
        end
        context "very long title" do
          let(:hypothesis_title) { "some title that is very long, so long that it is longer than the filename character limit because we want to be able to test the filename_slugify truncation method, so that we can test whether it finds the right thing after truncation given that it is suffixed with different things" }
          let(:hypothesis2_title) { "#{hypothesis_title} and extra bit" }
          it "finds the correct one" do
            hypothesis2.update(title: "whatever new title")
            StorePreviousHypothesisTitleJob.drain
            hypothesis2.reload
            expect(hypothesis2.previous_titles.pluck(:title)).to eq([hypothesis2_title])
            hypothesis.update(title: hypothesis_title2)
            StorePreviousHypothesisTitleJob.drain
            expect(hypothesis.previous_titles.pluck(:title)).to eq([hypothesis_title])
            expect(PreviousTitle.friendly_matching(hypothesis2_title).pluck(:hypothesis_id)).to eq([hypothesis2.id])
            expect(PreviousTitle.friendly_matching(hypothesis2_title.upcase).pluck(:hypothesis_id)).to eq([hypothesis2.id])
            expect(Hypothesis.friendly_find("#{hypothesis_title} and extra bit.")&.id).to eq hypothesis2.id
            # But if no extra bit is passed, it finds the more recent title
            expect(Hypothesis.friendly_find(hypothesis_title)&.id).to eq hypothesis.id
          end
        end
      end
    end
  end
end
