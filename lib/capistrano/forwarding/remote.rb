module Capistrano
  # Support SSH remote port forwarding
  module Forwarding
    class Remote
      # See lib/net/ssh/service/forward.rb
      class Forwarding
        # See lib/net/ssh/loggable.rb
        include Net::SSH::Loggable

        attr_reader :forwarding, :session

        def initialize(forwarding, session)
          @forwarding = forwarding
          @session    = session
          @logger     = session.logger
          raise ArgumentError, "Invalid forwarding" unless valid?
        end

        def to_s
          "#{session.host}:#{forwarding.join(":")}"
        end

        def forward!
          info { "forwarding remote #{self}" }
          session.forward.remote(*forwarding)
        end

        def cancel!
          info { "cancelling forwarding remote #{self}" }
          session.forward.cancel_remote(*remote_port_and_host)
        end

        def ready?
          session.forward.active_remotes.include?(remote_port_and_host)
        end

        def gone?
          !ready?
        end

        private

        # Default remote host is "127.0.0.1".
        # See /lib/net/ssh/service/forward.rb.
        def remote_port_and_host
          [forwarding[2], forwarding[3] || "127.0.0.1"]
        end

        def valid?
          forwarding.size == 3 || forwarding.size == 4
        end
      end

      include Processable

      attr_reader :sessions, :forwardings, :options

      def self.forward(forwardings, sessions, options = {}, &block)
        new(forwardings, sessions, options).forward!(&block)
      end

      def initialize(forwardings, sessions, options = {})
        sessions.each{|s| s.logger.level = Logger::INFO}

        @forwardings = sessions.map do |session|
          forwardings.map do |forwarding|
            Forwarding.new(forwarding, session)
          end
        end.flatten
        @sessions = sessions
        @options = options
      end

      def forward!
        start(options[:timeout])

        # If we use run or similar command in the block for the connections,
        # the forwardings are also processed by the loop of these commands.
        # See lib/capistrano/command.rb and lib/capistrano/processable.rb.
        yield(sessions) if block_given?

        # Since we may still have channels which are not completely processed by the
        # loop of these commands, run the loop for taking care of them until
        # all channels has been gone.
        loop unless options[:no_wait]

        stop(options[:timeout])
      end

      private

      def start(timeout = nil)
        forwardings.each{|f| f.forward!}
        # Process until all forward requests are ready.
        loop(timeout){ !ready? }
      end

      def stop(timeout = nil)
        forwardings.each{|f| f.cancel!}
        # Process until all forward cancel requests are accepted.
        loop(timeout){ !gone? }
      end

      # Preserve a reference to Kernel#loop
      alias :loop_forever :loop

      # Process until all channels in sessions are gone or while the block is true.
      # See /lib/net/ssh/connection/session.rb
      def loop(timeout = nil, &block)
        running = block || Proc.new { busy? }
        loop_forever{ break unless process_iteration(timeout, &running) }
      end

      def busy?
        sessions.any?(&:busy?)
      end

      def ready?
        forwardings.all?(&:ready?)
      end

      def gone?
        forwardings.all?(&:gone?)
      end
    end
  end

  class Configuration
    # Capistrano configuration example.
    # Forwarding remote port 3000 to local 3000 and ask remote hosts to HTTP GET
    # from local HTTP server running on port 3000.
    #   remote_forwarding [
    #     [3000, "127.0.0.1", 3000]
    #   ] do
    #     run "curl 'http://127.0.0.1:3000/'"
    #   end
    def remote_forwarding(fowardings, options = {})
      options = add_default_command_options(options)
      execute_on_servers(options) do |servers|
        targets = servers.map{|s| sessions[s]}
        Forwarding::Remote.forward(fowardings, targets) do
          yield
        end
      end
    end
  end
end
