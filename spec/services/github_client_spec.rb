require "rails_helper"

RSpec.describe GithubClient do
  let(:token) { "test_token" }
  let(:fake_octokit) { instance_double(Octokit::Client) }

  subject(:client) { described_class.new(token) }

  before do
    allow(Octokit::Client).to receive(:new).with(access_token: token).and_return(fake_octokit)
  end

  describe "#create_issue" do
    let(:fake_issue) { double(number: 7, html_url: "https://github.com/o/r/issues/7") }

    it "delegates to Octokit and returns number + url" do
      allow(fake_octokit).to receive(:create_issue).with("o/r", "title", "body").and_return(fake_issue)
      result = client.create_issue(repo: "o/r", title: "title", body: "body")
      expect(result).to eq(number: 7, url: "https://github.com/o/r/issues/7")
    end

    it "raises GithubClient::Error on Octokit::Error" do
      allow(fake_octokit).to receive(:create_issue).and_raise(Octokit::Error)
      expect {
        client.create_issue(repo: "o/r", title: "t", body: "b")
      }.to raise_error(GithubClient::Error)
    end
  end

  describe "#repos" do
    let(:fake_repos) { [double(full_name: "o/r1"), double(full_name: "o/r2")] }

    it "returns sorted repo full names" do
      allow(fake_octokit).to receive(:repos).with(nil, sort: "pushed", per_page: 100).and_return(fake_repos)
      expect(client.repos).to eq(%w[o/r1 o/r2])
    end

    it "raises GithubClient::Error on Octokit::Error" do
      allow(fake_octokit).to receive(:repos).and_raise(Octokit::Error)
      expect { client.repos }.to raise_error(GithubClient::Error)
    end
  end
end
