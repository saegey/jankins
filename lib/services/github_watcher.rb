module GithubWatcher
  class WebHook
    def self.dispatcher(response)
      res = RecursiveOpenStruct.new(JSON.parse(response))
      if res && res.respond_to?('action') && res.respond_to?('pull_request')
        jira_id = search_jira_id(res.pull_request.title)
        if res.pull_request.state == 'open'
          queue_build(res.pull_request, build_job, jira_id)
          Jira::IssueLinkWorker.perform_async(
            jira_id,
            res.pull_request.html_url,
            'Pull Request',
            'Pull Request'
          )
        end
      else
        return 'no pull request'
      end
    end

    private

    def self.search_jira_id(message)
      match = /API-\d*/.match(message)
      match ? match.to_s : false
    end

    def self.queue_build(pull_request, build_job, jira_id)
      Jenkins::BuildWorker.perform_async(
        pull_request.head.repo.owner.login,
        pull_request.head.ref,
        'MAT_API_Github_Integration_Test',
        jira_id,
        pull_request.head.repo.full_name,
        pull_request.number
      )
    end

    def self.build_job
      ENV['JENKINS_JOB']
    end
  end
end
