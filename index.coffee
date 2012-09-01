
class LazyLines

  [rCode, nCode] = ['\r'.charCodeAt(0), '\n'.charCodeAt(0)]

  constructor: (@stream) ->
    return new LazyLines(@stream) if @ not instanceof LazyLines
    @bufferedChunks = []
    @bufferedLength = 0
    @actions = []
    @encoding = 'utf-8'
    @stream.on('data', => onChunkReceived.apply(@, arguments))
    @stream.on('end', => onStreamEnd.apply(@, arguments))

  onChunkReceived = (chunk) ->
    firstUnhandledIndex = 0
    for chr, i in chunk
      if chr in [rCode, nCode]
        @bufferedChunks.push(chunk.slice(0, firstUnhandledIndex, i))
        @bufferedLength += i - firstUnhandledIndex
        onLineEndFound.call(@, chunk, i)
        i += 1 if chr == rCode and chunk[i+1] == nCode
        firstUnhandledIndex = i + 1
    #if firstUnhandledIndex != chunk.length
    @bufferedChunks.push(chunk.slice(firstUnhandledIndex))
    @bufferedLength += chunk.length - firstUnhandledIndex

  onStreamEnd = ->
    if @bufferedLength > 0
        onLineEndFound.call(@)

  onLineEndFound = ->
    if @encoding?
      line = (bufferedChunk.toString(@encoding) in @bufferedChunks).join('')
    else
      line = new Buffer(@bufferedLength)
      targetLength = 0
      for bufferedChunk in @bufferedChunks
        bufferedChunk.copy(line, targetLength)
        targetLength += bufferedChunk.length
    @bufferedChunks = []
    @bufferedLength = 0
    for action in @actions
      switch action.type
        when 'forEach' then action.f(line)
        when 'map' then line = action.f(line)
        when 'filter' then return if action.f(line) == false
    return

  setEncoding: (@encoding) ->
    return @

  forEach: (f) ->
    @actions.push({type: 'forEach', f: f})
    return @

  map: (f) ->
    @actions.push({type: 'map', f: f})
    return @

  filter: (f) ->
    @actions.push({type: 'filter', f: f})
    return @

module.exports = LazyLines
