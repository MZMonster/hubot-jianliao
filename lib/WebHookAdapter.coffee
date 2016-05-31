# Hubot dependencies
{Robot, Adapter, TextMessage, Response, User} = require 'hubot'
url = require('url')

###
Overrides parseChatMessage(body, req, res)
Overrides buildChatMessage({user, room, message}, text)
###
class WebHookAdapter extends Adapter
  run: ->
    @configReceiveHandler()

    @robot.logger.info "#{@robot.name} is online."

    @emit 'connected'

  logAndThrow: (message) ->
    @robot.logger.error(message)
    throw new Error(message)

  parseWebHookUrl: (pathOrUrl, defaultValue = '') ->
    parsedUrl = url.parse(pathOrUrl || defaultValue)

    if parsedUrl.protocol? and parsedUrl.protocol != 'https:'
      @robot.logger.warning('To ensure privacy and data security, web hook should be https')

    return parsedUrl

  ###
   * config POST API to receive jianliao message
  ###
  configReceiveHandler: ->
    parsedUrl = @parseWebHookUrl(process.env.HUBOT_CHAT_JIANLIAO, '/api/jianliao')

    unless parsedUrl.path?
      @logAndThrow('HUBOT_CHAT_OUTGOING_WEBHOOK must be set for hubot to recieve message from chat app')

    if parsedUrl.protocol? or parsedUrl.host? or parsedUrl.search?
      @robot.logger.warning('Chat Out Going Webhook should be a relative path')

    @jianliaoRouter = parsedUrl.pathname

    @robot.router.post @jianliaoRouter, @chatReceiveHandler this

    @robot.logger.info('Register Chat Outgoing Webhook at %s', @jianliaoRouter)

  ###
   * jianliao handler
   * reciver message
   *
   * Returns 200 to jianliao.
  ###
  chatReceiveHandler: (self) -> (req, res) ->
    self.robot.logger.debug req.body

    try
      message = self.parseChatMessage(req.body, req, res)
    catch ex
      self.robot.logger.error('Crashed when parsing chat message', ex)
      return

    self.robot.logger.info 'Recieved message: ', message
    self.respondChatMessageRequest(res, message, req)

    self.receive message


  parseChatMessage: (body) ->
    throw new Error('Derived class must return Messsage instance')

  respondChatMessageRequest: (res) ->
    res.status(200).end()

  buildChatMessage: (envelope, text) ->
    throw new Error('Derived class must return body for chat app')

  send: (envelope, strings...) ->
    @robot.logger.info "hubot is sending #{strings}"

    text = strings.join('\\n')
    @robot.logger.debug('joined response: ', text)

    @robot.logger.debug('envelope: ', envelope)

    {url, message} = @buildChatMessage(envelope, text)
    @robot.logger.debug("Output Body: ", message)

    json = JSON.stringify message

    @robot.http(url)
          .header('Content-Type', 'application/json')
          .post(json) (err, res, body) =>
            @robot.logger.info 'message sent', body

  reply: (user, strings...) ->
    @send user, strings...

  emote: (envelope, strings...) ->
    @send envelope, "* #{str}" for str in strings

module.exports = WebHookAdapter
