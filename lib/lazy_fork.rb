require "lazy_fork/version"
require "io/console"
require "octokit"

module LazyFork
  class LazyForker
    def initialize(options)
      @options = options

      # tell the user they're being a lazy fork
      puts "You lazy forker..."

      unless Dir.exist?(LAZY_FORK_HOME)
        puts "Creating #{LAZY_FORK_HOME}..."
        Dir.mkdir LAZY_FORK_HOME
      end

      authenticate_client
    end

    def fork
      clone_repo(fork_repo(get_repo(ARGV.first)), ARGV.last)
    end

    def fork?(repo)
      @client.repository(repo)[:fork]
    end

    def source(repo)
      source_slug = @client.repository(repo)[:source][:full_name]
      Octokit::Repository.new(source_slug)
    end

    private

    # Fork repo and return Octokit::Repository of newly forked repo
    def fork_repo(repo)
      Octokit::Repository.new(@client.fork(repo)[:full_name])
    end

    def clone_repo(repo, dest=".")
      `git clone #{repo.url} #{dest}`
    end

    def get_repo(repo)
      begin
        repo = Octokit::Repository.new(repo)
      rescue  Octokit::InvalidRepository
        puts "Invalid Repository: use owner/name format!"
        abort
      end

      unless @client.repository?(repo)
        puts "Repo #{repo.to_s} could not be found."
        abort
      end

      repo
    end

    def authenticate_client
      if File.exists?("#{LAZY_FORK_HOME}/oauth")
        puts "OAuth key found..."
        token = File.open("#{LAZY_FORK_HOME}/oauth", "r").read
        client = Octokit::Client.new(access_token: token)
      else
        puts "Basic Authentication"
        print "username: "
        user = gets.chomp
        print "password: "
        pass = STDIN.noecho(&:gets).chomp
        puts ""

        begin
          client = Octokit::Client.new(login: user, password: pass)
        rescue Octokit::Unauthorized
          puts "Bad Credentials!"
          abort
        end

        puts "Creating OAuth Token..."
        token = client.create_authorization(
          scopes: ["user","repo"],
          note: "Lazy Forker Access Token - #{('a'..'z').to_a.shuffle[0,8].join}")
        File.open("#{LAZY_FORK_HOME}/oauth",'w') do |s|
          s.puts token[:token]
        end

        puts "Token created in #{LAZY_FORK_HOME}/oauth"
      end

      @client = client
    end
  end
end
