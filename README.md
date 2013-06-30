# Capistrano SSH Port Forwarding Extension

Provide SSH port forwarding while deploying so that we can call
local service like [Spitball](https://github.com/freels/spitball) server from remote hosts.

Currently it supports only remote forwarding.

## Installation

Use bundler, add this line in your Gemfile:

    gem 'capistrano-forwarding'

Or install it yourself as:

    $ gem install capistrano-forwarding

## Usage

Currently it provides only `remote_forwarding` configuration
which is forwarding remote ports from remote hosts to local.

Here is an example in your `Capfile` or `config/deploy.rb`.

    require "capistrano/fowarding"

    desc "test task"
    task "test" do
      remote_forwarding [
        [3000, "127.0.0.1", 3000]
      ] do
        run "curl http://127.0.0.1:3000/"
      end
    end

Before trying this, run something like HTTP server on local port 3000.

    $ ruby -rwebrick -e 'WEBrick::HTTPServer.new(:Port => 3000).start'
