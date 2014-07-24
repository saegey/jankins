module GithubWatcher
  class WebHook
    def self.dispatcher(response)
      res = RecursiveOpenStruct.new(JSON.parse(response))
      if res && res.respond_to?('action') && res.respond_to?('pull_request')
        jira_id = search_jira_id(res.pull_request.title)
        if res.pull_request.state == 'open'
          queue_build(res.pull_request, jenkins_build_job, jira_id)
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
      match = /#{jira_project_prefix}-\d*/.match(message)
      match ? match.to_s : false
    end

    def self.queue_build(pull_request, build_job, jira_id)
      Jenkins::BuildWorker.perform_async(
        pull_request.head.repo.owner.login,
        pull_request.head.ref,
        build_job,
        jira_id,
        pull_request.head.repo.full_name,
        pull_request.number
      )
    end

    def self.jenkins_build_job
      ENV['JENKINS_JOB']
    end

    def self.jira_project_prefix
      ENV['JIRA_PROJECT_PREFIX']
    end
  end
end
