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
site_config = []

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

  # debugging to client console
  conn.write 'connected to SockJS'

  Application_Instance = false

  conn.on "data", (message) ->
    try
      client_payload = JSON.parse(message)

      if typeof client_payload is "object"
        payload_data = client_payload
        payload_data.session_start = Math.round(new Date().getTime() / 1000)

        # start application
        if typeof client_payload.application is "string"
          if Application_Instance is false
            try
              Application_Instance = require './applications/' + payload_data.application
              Application_Instance.prototype.onConnect()

              # debugging to client console
              conn.write('Application ' + payload_data.application + ' loaded')
            catch error
              console.log "Application %s not found.", payload_data.application
              return

        if typeof client_payload.data is "object"
          if client_payload.data.site_id isnt "null" and Application_Instance isnt false

            unless site_config[payload_data.data.site_id]
              site_configuration = require './config/sites/' + config.environment
              site_config[payload_data.data.site_id] = eval 'site_configuration.sites.site_' + payload_data.data.site_id

              # debugging to client console
              conn.write 'Site configuration for site ' + payload_data.data.site_id + ' loaded'
            else
              # debugging to client console
              conn.write 'Site configuration for site ' + payload_data.data.site_id + ' reused'

            # setup redis connection if not present for site
            unless redis_connections[payload_data.data.site_id]
              redis_connections[payload_data.data.site_id] = redis.createClient(site_config[payload_data.data.site_id].redis_master_port, 
                                                                                  site_config[payload_data.data.site_id].redis_master_host)
              redis_connections[payload_data.data.site_id].select(site_config[payload_data.data.site_id].redis_db)

              # debugging to client console
              conn.write 'Redis connection for site ' + payload_data.data.site_id + ' established'
            else
              # debugging to client console
              conn.write 'Redis connection for site ' + payload_data.data.site_id + ' reused'

            # export redis connection
            exports.libs.Redis = redis_connections[payload_data.data.site_id]

            # export site configuration
            exports.libs.SiteConfig = site_config[payload_data.data.site_id]

          # handle messages
          if client_payload.data.message isnt "null" and Application_Instance isnt false
              Application_Instance.prototype.onMessage(payload_data.data.message)

              # debugging to client console
              conn.write(payload_data.data.message)

    catch Exception
      console.log 'Error: Unknown action %s', Exception

  conn.on "close", ->
    unless Application_Instance is false
      Application_Instance.prototype.onDisconnect()

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