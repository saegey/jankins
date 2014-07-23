Bundler.require

module Jenkins
  class Build
    attr_accessor :client, :job_name, :id, :errors, :status

    def initialize(job_name)
      @client = self.class.api_client
      @job_name = job_name
      @errors = []
    end

    def url
      "#{self.class.jenkins_url}/view/MAT%20api/job/#{@job_name}/#{@id}/console"
    end

    def self.trigger(fork, branch, job_name)
      instance = self.new(job_name)
      opts = { 'build_start_timeout' => 1800 }
      job_params = { fork: fork, branch: branch }
      instance.id = instance.client.job.build(job_name, job_params, opts)
      instance
    end

    def self.output(id, job_name)
      errors = []
      status = ""
      instance = self.new(job_name)
      instance.id = id
      console_output = instance.client.job.get_console_output(
        job_name, id, 0, 'html'
      );
      lines = console_output['output'].split("\r\n")
      lines.each_with_index do |line, index|
        if /^\d*\)/.match(line)
          instance.errors << "#{line} – #{lines[index + 1]}"
        elsif /^Finished\:/.match(line)
          instance.status = line.split(":").last.strip
        end
      end
      instance
    end

    private

    def self.api_client
      client = JenkinsApi::Client.new(
        server_url: self.jenkins_url,
        username: ENV['JENKINS_USERNAME'],
        password: ENV['JENKINS_PASSWORD']
      )
    end

    def self.jenkins_url
      ENV['JENKINS_URL']
    end
  end

  class BuildWorker
    include Sidekiq::Worker

    def perform(fork, branch, job_name, jira_id, repo_name, issue_id)
      build = Jenkins::Build.trigger(fork, branch, job_name)
      jenkins_output_wait_secs = 60
      Jenkins::BuildOutputWorker.perform_in(
        jenkins_output_wait_secs, build.id, job_name, repo_name, issue_id
      )
      Jira::IssueLinkWorker.perform_async(
        jira_id, build.url, 'Jenkins', 'Jenkins'
      )
    end
  end

  class BuildOutputWorker
    include Sidekiq::Worker

    def perform(build_id, build_job, repo_name, issue_id)
      build = Jenkins::Build.output(build_id, build_job)
      comment = Github::IssueComment.new(repo_name, issue_id)
      comment.jenkins_message(build.status, build.url, build.errors)
    end
  end
end
