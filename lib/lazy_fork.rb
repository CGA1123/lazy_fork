require "lazy_fork/version"

require "optparse"
require "io/console"

module LazyFork
  class LazyForker
    def initialize(options)
      @options = options
      @client = nil

      # tell the user their being a lazy fork
      puts "You lazy forker... v#{LazyFork::VERSION}"

      unless Dir.exist? LAZY_FORK_HOME
        puts "Creating #{LAZY_FORK_HOME}..."
        Dir.mkdir LAZY_FORK_HOME
      end
    end

    def be_lazy
      authenticate_client
      get_repo(ARGV.first)
      fork_repo
      clone_repo
    end

    private

    def fork_repo
      puts "Forking..."
      fork_repo = @client.fork(@repo)
      @forked_repo = Octokit::Repository.new(fork_repo[:full_name])
    end

    def clone_repo
      puts "Cloning fork (#{@forked_repo.to_s})..."
      `git clone #{@forked_repo.url} #{ARGV[1]}`
    end

    def get_repo(repo)
      begin
        @repo = Octokit::Repository.new(repo)
      rescue  Octokit::InvalidRepository
        puts "Invalid Repository: use owner/name format!"
        abort
      end

      unless @client.repository?(@repo)
        puts "Repo #{@repo.to_s} could not be found."
        abort
      end
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
