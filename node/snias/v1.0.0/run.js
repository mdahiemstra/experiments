// Generated by CoffeeScript 1.4.0

/*
S.N.I.A.S - Single Node Instance Application Server
Author: Michel Hiemstra <mhiemstra@php.net>
version: v1.0.0
*/


(function() {
  var config, http, nstatic, payload_data, redis, redis_connections, site_config, sockjs, sockjs_options, sockjs_server, static_server;

  http = require('http');

  sockjs = require('sockjs');

  nstatic = require('node-static');

  config = require('./config/run');

  redis = require('redis');

  exports.libs = {
    Config: config
  };

  redis_connections = [];

  site_config = [];

  sockjs_options = {
    sockjs_url: config.sock.client_url,
    response_limit: config.sock.response_limit,
    websocket: config.sock.websocket,
    jsessionid: config.sock.jsessionid,
    heartbeat_delay: config.sock.heartbeat_delay,
    disconnect_delay: config.sock.disconnect_delay,
    log: function(s, e) {
      if (e === "error") {
        return console.log("SockJS Error: " + e);
      }
    }
  };

  sockjs_server = sockjs.createServer(sockjs_options);

  payload_data = {};

  sockjs_server.on("connection", function(conn) {
    var Application_Instance;
    conn.write('connected to SockJS');
    Application_Instance = false;
    conn.on("data", function(message) {
      var client_payload, site_configuration;
      try {
        client_payload = JSON.parse(message);
        if (typeof client_payload === "object") {
          payload_data = client_payload;
          payload_data.session_start = Math.round(new Date().getTime() / 1000);
          if (typeof client_payload.application === "string") {
            if (Application_Instance === false) {
              try {
                Application_Instance = require('./applications/' + payload_data.application);
                Application_Instance.prototype.onConnect();
                conn.write('Application ' + payload_data.application + ' loaded');
              } catch (error) {
                console.log("Application %s not found.", payload_data.application);
                return;
              }
            }
          }
          if (typeof client_payload.data === "object") {
            if (client_payload.data.site_id !== "null" && Application_Instance !== false) {
              if (!site_config[payload_data.data.site_id]) {
                site_configuration = require('./config/sites/' + config.environment);
                site_config[payload_data.data.site_id] = eval('site_configuration.sites.site_' + payload_data.data.site_id);
                conn.write('Site configuration for site ' + payload_data.data.site_id + ' loaded');
              } else {
                conn.write('Site configuration for site ' + payload_data.data.site_id + ' reused');
              }
              if (!redis_connections[payload_data.data.site_id]) {
                redis_connections[payload_data.data.site_id] = redis.createClient(site_config[payload_data.data.site_id].redis_master_port, site_config[payload_data.data.site_id].redis_master_host);
                redis_connections[payload_data.data.site_id].select(site_config[payload_data.data.site_id].redis_db);
                conn.write('Redis connection for site ' + payload_data.data.site_id + ' established');
              } else {
                conn.write('Redis connection for site ' + payload_data.data.site_id + ' reused');
              }
              exports.libs.Redis = redis_connections[payload_data.data.site_id];
              exports.libs.SiteConfig = site_config[payload_data.data.site_id];
            }
            if (client_payload.data.message !== "null" && Application_Instance !== false) {
              Application_Instance.prototype.onMessage(payload_data.data.message);
              return conn.write(payload_data.data.message);
            }
          }
        }
      } catch (Exception) {
        return console.log('Error: Unknown action %s', Exception);
      }
    });
    return conn.on("close", function() {
      if (Application_Instance !== false) {
        return Application_Instance.prototype.onDisconnect();
      }
    });
  });

  static_server = http.createServer();

  static_server.addListener("request", function(req, res) {
    return new nstatic.Server(__dirname).serve(req, res);
  });

  static_server.addListener("upgrade", function(req, res) {
    return res.end();
  });

  sockjs_server.installHandlers(static_server, {
    prefix: config.sock.prefix
  });

  try {
    static_server.listen(config.sock.listen.port, config.sock.listen.host);
    console.log("INFO: %s - SockJS started listening", new Date());
  } catch (Exception) {
    console.log("ERROR: %s - %s", new Date(), Exception);
  }

  process.once("exit", function(code) {
    code = code || 0;
    console.log("NOTICE: %s - SockJS exiting with code %s", new Date(), code);
    return process.exit(code);
  });

  process.on("SIGINT", function() {
    return process.exit(2);
  });

  process.on("SIGTERM", function() {
    return process.exit(0);
  });

}).call(this);
