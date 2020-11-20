# frozen_string_literal: true

shared_context :logged_in_as_user do
  let(:current_user) { FactoryBot.create(:user) }
  before { sign_in current_user }
end

shared_context :logged_in_as_developer do
  let(:current_user) { FactoryBot.create(:user, role: "developer") }
  before { sign_in current_user }
end

# Request spec helpers that are included in all request specs via Rspec.configure (rails_helper)
module RequestSpecHelpers
  def json_headers
    {"CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"}
  end

  def json_result
    r = JSON.parse(response.body)
    r.is_a?(Hash) ? r.with_indifferent_access : r
  end
end
