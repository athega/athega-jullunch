window.tick = -> (new Date().getTime())

class window.PrettyDate
  parse: (date) =>
    date    = date.split('-').join('/')
    seconds = parseInt((new Date - new Date(date)) / 1000)
    seconds = 0 if seconds < 0

    for f in @formats
      if seconds < f[0]
        format = f
        break

    if format[2]
      Math.floor(seconds/format[2]) + ' ' + format[1] + ' sedan'
    else
      format[1]

  formats: [
    [60, 'sekunder', 1],
    [120, '1 minut sedan'],
    [3600, 'minuter', 60],
    [7200, '1 timme sedan'],
    [86400, 'timmar', 3600],
    [172800, 'Igår'],
    [604800, 'dagar', 86400],
    [1209600, '1 vecka sedan'],
    [2419200, 'weeks', 604800],
    [4838400, 'förra månaden'],
    [29030400, 'månader', 2419200],
    [58060800, 'förra året'],
    [2903040000, 'år', 29030400]
  ]

###############################################################################
# Views
###############################################################################

class window.ListView extends Backbone.View
  el: '#app'

  initialize: ->
    _.bindAll(@, 'render')
    @collection.bind 'reset', @render

  render: ->
    $(@el).html @template()(@data())

    pd = new PrettyDate()

    $(@el).find('.timestamp').each (index, element) =>
      e = $(element)
      e.html(pd.parse(e.attr('data-timestamp')))

    @

  data: ->
    { 'items': @collection.map (m) -> m.toJSON() }

class window.AdsView extends ListView
  class_name: 'ads'
  template: -> ich.ads_tpl
  data: -> { 'random_url': _.shuffle(@collection.models)[1].get('url') }

class window.CheckInsView extends ListView
  class_name: 'check_ins'
  template: -> ich.check_ins_tpl

class window.ImagesView extends ListView
  class_name: 'images'
  template: -> ich.images_tpl
  data: -> { 'items': (@collection.map (m) -> m.toJSON()).slice(0, 12) }

class window.TweetsView extends ListView
  class_name: 'tweets'
  template: -> ich.tweets_tpl

###############################################################################
# Router
###############################################################################

class window.Router extends Backbone.Router
  routes:
    '':           'loop'
    'ads':        'ads'
    'check-ins':  'check_ins'
    'images':     'images'
    'tweets':     'tweets'
    'loop':       'loop'

  ads: ->
    ads.fetch()

  check_ins: ->
    check_ins.fetch()

  images: ->
    images.fetch()

  tweets: ->
    tweets.fetch()

  loop: -> new PresentationLoop(12000)

###############################################################################
# Models
###############################################################################

class window.Ad extends Backbone.Model
class window.CheckIn extends Backbone.Model
class window.Image extends Backbone.Model

class window.Tweet extends Backbone.Model
  initialize: (attrs) ->
    if attrs.text
      @set { html: @htmlDecode(attrs.text) }, { silent: true }

  htmlDecode: (value) ->
    $('<div/>').html(value).text()


###############################################################################
# Collections
###############################################################################

class window.Ads extends Backbone.Collection
  model: Ad
  url: 'http://assets.athega.se/jullunch/ads.json'

class window.CheckIns extends Backbone.Collection
  model: CheckIn
  url: '/data/latest_check_ins.json'

class window.Images extends Backbone.Collection
  model: Image
  url: 'http://assets.athega.se/jullunch/latest_images.json?' + tick()

class window.Tweets extends Backbone.Collection
  model: Tweet
  url: 'http://assets.athega.se/jullunch/tweets.json'

###############################################################################
# Presentation loop
###############################################################################

class window.PresentationLoop

  constructor: (ms) ->
    @delay     = ms
    @iteration = 0

    window.loop = @
    window.loop.run()

  tweets: ->
    tweets.fetch()
    setTimeout 'tweets.fetch()', @delay/2
    setTimeout 'window.loop.check_ins()', @delay

  check_ins: ->
    check_ins.fetch()
    setTimeout 'window.loop.images()', @delay

  images: ->
    images.fetch()
    setTimeout 'images.fetch()', @delay/2
    setTimeout 'window.loop.ads()', @delay

  ads: ->
    ads.fetch()
    setTimeout 'window.loop.iterate()', @delay

  iterate: ->
    @iteration += 1
    console.log('iteration: ' + @iteration)
    setTimeout 'window.loop.tweets()', 0

  run: ->
    setTimeout (=> @tweets()), 0

###############################################################################
# Application start (on document ready)
###############################################################################

window.app      = {}
app.views       = {}

$ ->
  if(navigator.platform.indexOf("iPad") != -1)
    $(document).bind 'touchmove', (e) ->
      e.preventDefault()

  window.ads          = new Ads()
  window.check_ins    = new CheckIns()
  window.images       = new Images()
  window.tweets       = new Tweets()

  app.router          = new Router()
  app.views.ads       = new AdsView({ collection: ads })
  app.views.check_ins = new CheckInsView({ collection: check_ins })
  app.views.images    = new ImagesView({ collection: images })
  app.views.tweets    = new TweetsView({ collection: tweets })

  Backbone.history.start({pushState: true})
