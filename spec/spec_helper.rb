require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/daemon'

require 'rubygems'
require 'mocha'
require 'ruby-debug' rescue nil

ActionMailer::Base.delivery_method = :test
$test_mode = true

module Radical
  class Daemon
    # do not loop.  this will make it testable.
    def do_run
      tick
    end
  end
end

class SSHObject < OpenStruct
  attr_accessor :options

  def initialize(options = {})
  end

  def on_data
    yield SSHObject.new, ""
  end

  def on_extended_data
    yield SSHObject.new, "", ""
  end

  def read_long
    ""
  end

  def upload!(from, to)
    nil
  end

  def scp
    SSHObject.new
  end

  def on_request(item)
    yield SSHObject.new, SSHObject.new
  end
end
