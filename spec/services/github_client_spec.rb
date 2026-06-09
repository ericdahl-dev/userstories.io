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

  describe "#get_issue" do
    let(:fake_issue) { double(:issue) }

    it "delegates to Octokit and returns the issue" do
      allow(fake_octokit).to receive(:issue).with("o/r", 7).and_return(fake_issue)
      expect(client.get_issue(repo: "o/r", number: 7)).to eq(fake_issue)
    end

    it "raises GithubClient::Error on Octokit::Error" do
      allow(fake_octokit).to receive(:issue).and_raise(Octokit::Error)
      expect { client.get_issue(repo: "o/r", number: 7) }.to raise_error(GithubClient::Error)
    end
  end

  describe "#repos" do
    let(:fake_repos) { [ double(full_name: "o/r1"), double(full_name: "o/r2") ] }

    it "returns sorted repo full names" do
      allow(fake_octokit).to receive(:repos).with(nil, sort: "pushed", per_page: 100).and_return(fake_repos)
      expect(client.repos).to eq(%w[o/r1 o/r2])
    end

    it "raises GithubClient::Error on Octokit::Error" do
      allow(fake_octokit).to receive(:repos).and_raise(Octokit::Error)
      expect { client.repos }.to raise_error(GithubClient::Error)
    end
  end

  describe "#file_content" do
    it "returns decoded file content" do
      entry = double(type: "file", size: 100, content: Base64.encode64("class App\nend"))
      allow(fake_octokit).to receive(:contents).with("o/r", path: "README.md").and_return(entry)

      expect(client.file_content(repo: "o/r", path: "README.md")).to eq("class App\nend")
    end

    it "returns nil for directories" do
      allow(fake_octokit).to receive(:contents).with("o/r", path: "app").and_return([])

      expect(client.file_content(repo: "o/r", path: "app")).to be_nil
    end

    it "returns nil for oversized files" do
      entry = double(type: "file", size: 9.kilobytes, content: "ignored")
      allow(fake_octokit).to receive(:contents).with("o/r", path: "big.rb").and_return(entry)

      expect(client.file_content(repo: "o/r", path: "big.rb")).to be_nil
    end

    it "returns nil when the path is missing" do
      allow(fake_octokit).to receive(:contents).and_raise(Octokit::NotFound)

      expect(client.file_content(repo: "o/r", path: "missing.rb")).to be_nil
    end

    it "raises GithubClient::Error on Octokit::Error" do
      allow(fake_octokit).to receive(:contents).and_raise(Octokit::Error)
      expect { client.file_content(repo: "o/r", path: "app.rb") }.to raise_error(GithubClient::Error)
    end
  end

  describe "#directory_paths" do
    it "returns eligible file paths in a directory" do
      entries = [
        double(type: "file", path: "app/models/user.rb", size: 100),
        double(type: "dir", path: "app/views", size: 0),
        double(type: "file", path: "spec/models/user_spec.rb", size: 100),
        double(type: "file", path: "app/logo.png", size: 100)
      ]
      allow(fake_octokit).to receive(:contents).with("o/r", path: "app").and_return(entries)

      expect(client.directory_paths(repo: "o/r", path: "app")).to eq([ "app/models/user.rb" ])
    end

    it "returns an empty array when the directory is missing" do
      allow(fake_octokit).to receive(:contents).and_raise(Octokit::NotFound)

      expect(client.directory_paths(repo: "o/r", path: "missing")).to eq([])
    end

    it "raises GithubClient::Error on Octokit::Error" do
      allow(fake_octokit).to receive(:contents).and_raise(Octokit::Error)
      expect { client.directory_paths(repo: "o/r", path: "app") }.to raise_error(GithubClient::Error)
    end
  end
end
