console.log('Started application test\n------------------------')

Super = require '../run'

###
    Libraries available in Super, e.g. Super.libs.Redis, Super.libs.SiteConfig
###

class Application
    onConnect: ->
        console.log 'Connected'
    onMessage: (message) ->
        console.log "Message received: #{message}"
    onReconnect: ->
        console.log 'Reconnected'
    onDisconnect: ->
        console.log 'Disconnected'

module.exports = Application