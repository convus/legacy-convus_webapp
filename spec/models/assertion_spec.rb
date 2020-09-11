require "rails_helper"

RSpec.describe Assertion, type: :model do
  it_behaves_like "TitleSluggable"
end
