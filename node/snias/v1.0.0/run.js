// Generated by CoffeeScript 1.4.0

/*
S.N.I.A.S - Single Node Instance Application Server
Author: Michel Hiemstra <mhiemstra@php.net>
version: v1.0.0
*/


(function() {
  var Application, config, http, nstatic, redis, run_app, sockjs, util;

  http = require('http');

  sockjs = require('sockjs');

  nstatic = require('node-static');

  config = require('./config/run');

  redis = require('redis');

  util = require('util');

  run_app = 'test';

  try {
    Application = require('./applications/' + run_app);
  } catch (error) {
    console.log("Application " + run_app + " not found.");
    return;
  }

  Application.prototype.onConnect();

  Application.prototype.onMessage('Testing the application');

  Application.prototype.onDisconnect();

}).call(this);
