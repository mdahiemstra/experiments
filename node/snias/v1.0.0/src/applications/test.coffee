console.log('Started application test\n------------------------')

#Initialize = klass -> console.log('yes')
#Initialize = -> console.log('test')

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