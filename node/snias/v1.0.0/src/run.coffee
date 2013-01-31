###
S.N.I.A.S - Single Node Instance Application Server
Author: Michel Hiemstra <mhiemstra@php.net>
version: v1.0.0
###
http    = require 'http'
sockjs  = require 'sockjs'
nstatic = require 'node-static'
config  = require './config/run'
redis   = require 'redis'
util    = require 'util'

run_app = 'test'

try 
    Application = require './applications/' + run_app
catch error
    console.log "Application #{run_app} not found."
    return

# simulate a connection
Application.prototype.onConnect()

# simulate a message
Application.prototype.onMessage ('Testing the application')

# simulate a disconnect
Application.prototype.onDisconnect()