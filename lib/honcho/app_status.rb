require 'time'
require 'timeout'

module Honcho
  class AppStatus
    def initialize(name, path:)
      @name = name
      @path = path
    end

    def data
      return {} unless path_exists?
      threads = [
        Thread.new { @sha1          = fetch_sha1          },
        Thread.new { @branch        = fetch_branch        },
        Thread.new { @commits_ahead = fetch_commits_ahead }
      ]
      threads.each(&:join)
      {
        sha1:          @sha1,
        branch:        @branch,
        commits_ahead: @commits_ahead
      }
    end

    private

    def fetch_sha1
      `cd #{@path} && git rev-parse HEAD 2>/dev/null`.strip
    end

    def fetch_branch
      `cd #{@path} && git symbolic-ref --short HEAD 2>/dev/null`.strip
    end

    REMOTE_REF_STALE_TIME = 60 * 60 # 1 hour
    FETCH_ORIGIN_TIMEOUT = 3

    def fetch_commits_ahead
      remote_branch = `cd #{@path} && git rev-parse --symbolic-full-name --abbrev-ref @{u} 2>/dev/null`.strip
      remote_ref_path = File.join(@path, ".git/refs/remotes/#{remote_branch}")
      return 0 unless File.exist?(remote_ref_path)
      if File.stat(remote_ref_path).mtime < Time.now - REMOTE_REF_STALE_TIME
        begin
          status = Timeout.timeout(FETCH_ORIGIN_TIMEOUT) do
            `cd #{@path} && git fetch origin && git status && touch #{remote_ref_path}`
          end
        rescue Timeout::Error
          status = `cd #{@path} && git status`
        end
      else
        status = `cd #{@path} && git status`
      end
      return 0 unless status =~ /Your branch is behind.*by (\d+) commits?/
      $1.to_i
    end

    def path_exists?
      File.exist?(@path)
    end
  end
end
