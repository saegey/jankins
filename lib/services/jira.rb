Bundler.require

module Jira
  class Issue
    attr_accessor :conn, :links, :id, :link

    def initialize
      @conn = self.class.connection
      @link = {}
    end

    def self.find(id)
      instance = self.new
      response = instance.conn.get(
        "/rest/api/2/issue/#{CGI.escape(id)}/remotelink"
      )
      instance.links = JSON.parse(response.body)
      instance.id = id
      instance
    end

    def create
      if @link.empty? == false
        response = conn.post do |req|
          req.url "/rest/api/2/issue/#{@id}/remotelink"
          req.headers['Content-Type'] = 'application/json'
          req.body = @link.to_json
        end
        if response.status == 201
          true
        else
          raise "unable to save jira link for: #{@id} Error: #{response.status}"
        end
      else
        nil
      end
    end

    def update
      if @link.length
        response = conn.put do |req|
          req.url "/rest/api/2/issue/#{@id}/remotelink/#{@link['id']}"
          req.headers['Content-Type'] = 'application/json'
          req.body = @link.to_json
        end
        if response.status == 204
          true
        else
          raise "unable to save jira link for: #{@id} link_id: #{@link['id']} Error: #{response.status}"
        end
      end
    end

    private

    def self.connection
      conn = Faraday.new(url: ENV['JIRA_URL']) do |faraday|
        # faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
      conn.basic_auth(ENV['JIRA_USERNAME'], ENV['JIRA_PASSWORD'])
      conn
    end
  end

  class IssueLinkWorker
    include Sidekiq::Worker

    def perform(id, url, title, search_phrase = false)
      issue = Jira::Issue.find(id)
      found_issue = false

      if issue.links.empty? == false && search_phrase
        issue.links.each do |l|
          if /#{search_phrase}/.match(l['object']['title'])
            issue.link = l
            issue.link['object'] = { url: url, title: title }
            issue.update
            found_issue = true
            #so we only update 1 link due to more being manually added
            break
          end
        end
      end

      if found_issue == false
        issue.link = {
          object: {
            url: url,
            title: title
          }
        }
        issue.create
      end
    end
  end
end
