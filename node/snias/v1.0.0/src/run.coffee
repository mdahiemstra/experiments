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

# export the libraries
exports.libs = { Config: config }

redis_connections = []

sockjs_options = {
    sockjs_url:       config.sock.client_url,
    response_limit:   config.sock.response_limit,
    websocket:        config.sock.websocket,
    jsessionid:       config.sock.jsessionid,
    heartbeat_delay:  config.sock.heartbeat_delay,
    disconnect_delay: config.sock.disconnect_delay,
    log: (s, e) ->
        if e is "error"
          console.log("SockJS Error: #{e}")
}

sockjs_server = sockjs.createServer(sockjs_options)

payload_data = {}

sockjs_server.on "connection", (conn) ->

    Application = false

    conn.on "data", (message) ->
        try
            client_payload = JSON.parse(message)

            if typeof client_payload is "object"
                payload_data = client_payload
                payload_data.session_start = Math.round(new Date().getTime() / 1000)

                # start application
                if typeof client_payload.application is "string"
                    if Application is false
                        try
                            Application = require './applications/' + client_payload.application
                            Application.prototype.onConnect()
                        catch error
                            console.log "Application %s not found.", client_payload.application
                            return

                if typeof client_payload.data is "object"
                    # setup redis connection if not present for site
                    if client_payload.data.site_id isnt "null" and Application isnt false
                        unless redis_connections[client_payload.data.site_id]
                            redis_connections[client_payload.data.site_id] = redis.createClient(6379, "localhost")
                            redis_connections[client_payload.data.site_id].select(1)

                        # export redis connection
                        exports.libs.Redis = redis_connections[client_payload.data.site_id]

                    # handle messages
                    if client_payload.data.message isnt "null" and Application isnt false
                        Application.prototype.onMessage(client_payload.data.message)

        catch Exception
            console.log 'Error: Unknown action %s', Exception

    conn.on "close", ->
        unless Application is false
            Application.prototype.onDisconnect()

static_server = http.createServer()

static_server.addListener "request", (req, res) ->
  new nstatic.Server(__dirname).serve req, res

static_server.addListener "upgrade", (req, res) ->
  res.end()

sockjs_server.installHandlers static_server,
  prefix: config.sock.prefix

try
  static_server.listen config.sock.listen.port, config.sock.listen.host
  console.log "INFO: %s - SockJS started listening", new Date()
catch Exception
  console.log "ERROR: %s - %s", new Date(), Exception

process.once "exit", (code) ->
  code = code or 0
  console.log "NOTICE: %s - SockJS exiting with code %s", new Date(), code
  process.exit code

process.on "SIGINT", ->
  process.exit 2

process.on "SIGTERM", ->
  process.exit 0