require "lazy_fork/version"
require "io/console"
require "octokit"

module LazyFork
  class LazyForker
    def self.fork(source, destination)
      new.fork(source, destination)
    end

    attr_reader :source, :destination, :client

    def initialize(source, destination)
      # tell the user they're being a lazy fork
      puts "You lazy forker..."

      create_lazy_fork_home

      @source = source
      @destination = destination
      @client = authenticate_client
    end

    def fork
      repo = fork_repo
      clone(repo)
    end

    private

    # Fork repo and return Octokit::Repository of newly forked repo
    def fork_repo
      Octokit::Repository.new(client.fork(get_repo)[:full_name])
    end

    def clone(repo)
      `git clone #{repo.url} #{destination}`
      `cd #{destination}`
      `git remote add upstream #{repo.url}`
    end

    def get_repo
      repo = Octokit::Repository.new(source)

      unless client.repository?(repo)
        puts "Repo #{repo.to_s} could not be found."
        abort
      end

      repo
    rescue  Octokit::InvalidRepository
      puts "Invalid Repository: use owner/name format!"
      abort
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

      client
    end

    def create_lazy_fork_home
      unless Dir.exist?(LAZY_FORK_HOME)
        puts "Creating #{LAZY_FORK_HOME}..."
        Dir.mkdir LAZY_FORK_HOME
      end
    end
  end
end
