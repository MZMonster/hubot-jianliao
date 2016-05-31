{TextMessage, User} = require 'hubot'
WebHookAdapter = require('./WebHookAdapter')

class JianLiaoAdapter extends WebHookAdapter
  constructor: ->
    super

  cleanText: (text = '') ->
    text = text.trim()
    "#{@robot.name} #{text}"


  parseChatMessage: (message) ->
    return unless message?._id and message._creatorId and
      message._teamId and message.incoming?.url

    text = @cleanText message.body
    userInfo =
      room: message.room or message.team,
      creator: message.incoming._id
      url: message.incoming.url
      _teamId: message._teamId

    if message.room
      userInfo._roomId = message._roomId
      userInfo.mention =
        _id: message._creatorId
        name: message.creator.name
    else
      userInfo._toId = message._creatorId

    user = new User message._creatorId, userInfo

    new TextMessage(user, text, message._id)

  buildChatMessage: (envelope, text) ->
    return unless envelope?.user
    user = envelope.user

    @robot.logger.debug 'envelope', user

    message =
      content: text
      creator: user.creator
      team: user._teamId
      displayType: 'markdown'

    if user._roomId
      message._roomId = user._roomId
      message.mention = user.mention
    else
      message._toId = user._toId

    {url: user.url, message: message}

exports.use = (robot) ->
  new JianLiaoAdapter robot
