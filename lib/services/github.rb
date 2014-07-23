module Github
  class IssueComment
    attr_accessor :repo, :issue_number, :message

    def initialize(repo, issue_number, message = nil)
      @repo, @issue_number, @message = repo, issue_number, message
      @client = self.class.client
    end

    def save
      @client.add_comment(@repo, @issue_number, message, options = {})
    end


    def jenkins_message(status, url, errors)
      lines = []
      lines << '**Jenkins Build Status**' + "\r\n" + status
      lines << '**Build Link** '+ "\r\n" + url
      if errors.length > 0
        lines << '```'
        lines << errors.join("\r\n")
        lines << '```'
      end
      @message = lines.join("\r\n")
    end

    private

    def self.client
      client = Octokit::Client.new(
        login: ENV['GITHUB_USERNAME'],
        password: ENV['GITHUB_PASSWORD']
      )
    end
  end
end
