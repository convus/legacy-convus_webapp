require "rails_helper"

RSpec.describe Hypothesis, type: :model do
  it_behaves_like "TitleSluggable"
end
