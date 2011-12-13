(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  window.tick = function() {
    return new Date().getTime();
  };

  window.PrettyDate = (function() {

    function PrettyDate() {
      this.parse = __bind(this.parse, this);
    }

    PrettyDate.prototype.parse = function(date) {
      var f, format, seconds, _i, _len, _ref;
      date = date.split('-').join('/');
      seconds = parseInt((new Date - new Date(date)) / 1000);
      if (seconds < 0) seconds = 0;
      _ref = this.formats;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        if (seconds < f[0]) {
          format = f;
          break;
        }
      }
      if (format[2]) {
        return Math.floor(seconds / format[2]) + ' ' + format[1] + ' sedan';
      } else {
        return format[1];
      }
    };

    PrettyDate.prototype.formats = [[60, 'sekunder', 1], [120, '1 minut sedan'], [3600, 'minuter', 60], [7200, '1 timme sedan'], [86400, 'timmar', 3600], [172800, 'Igår'], [604800, 'dagar', 86400], [1209600, '1 vecka sedan'], [2419200, 'weeks', 604800], [4838400, 'förra månaden'], [29030400, 'månader', 2419200], [58060800, 'förra året'], [2903040000, 'år', 29030400]];

    return PrettyDate;

  })();

  window.ListView = (function() {

    __extends(ListView, Backbone.View);

    function ListView() {
      ListView.__super__.constructor.apply(this, arguments);
    }

    ListView.prototype.el = '#app';

    ListView.prototype.initialize = function() {
      _.bindAll(this, 'render');
      return this.collection.bind('reset', this.render);
    };

    ListView.prototype.render = function() {
      var pd;
      var _this = this;
      $(this.el).html(this.template()(this.data()));
      pd = new PrettyDate();
      $(this.el).find('.timestamp').each(function(index, element) {
        var e;
        e = $(element);
        return e.html(pd.parse(e.attr('data-timestamp')));
      });
      return this;
    };

    ListView.prototype.data = function() {
      return {
        'items': this.collection.map(function(m) {
          return m.toJSON();
        })
      };
    };

    return ListView;

  })();

  window.AdsView = (function() {

    __extends(AdsView, ListView);

    function AdsView() {
      AdsView.__super__.constructor.apply(this, arguments);
    }

    AdsView.prototype.class_name = 'ads';

    AdsView.prototype.template = function() {
      return ich.ads_tpl;
    };

    AdsView.prototype.data = function() {
      return {
        'random_url': _.shuffle(this.collection.models)[1].get('url')
      };
    };

    return AdsView;

  })();

  window.CheckInsView = (function() {

    __extends(CheckInsView, ListView);

    function CheckInsView() {
      CheckInsView.__super__.constructor.apply(this, arguments);
    }

    CheckInsView.prototype.class_name = 'check_ins';

    CheckInsView.prototype.template = function() {
      return ich.check_ins_tpl;
    };

    return CheckInsView;

  })();

  window.ImagesView = (function() {

    __extends(ImagesView, ListView);

    function ImagesView() {
      ImagesView.__super__.constructor.apply(this, arguments);
    }

    ImagesView.prototype.class_name = 'images';

    ImagesView.prototype.template = function() {
      return ich.images_tpl;
    };

    ImagesView.prototype.data = function() {
      return {
        'items': (this.collection.map(function(m) {
          return m.toJSON();
        })).slice(0, 12)
      };
    };

    return ImagesView;

  })();

  window.TweetsView = (function() {

    __extends(TweetsView, ListView);

    function TweetsView() {
      TweetsView.__super__.constructor.apply(this, arguments);
    }

    TweetsView.prototype.class_name = 'tweets';

    TweetsView.prototype.template = function() {
      return ich.tweets_tpl;
    };

    return TweetsView;

  })();

  window.Router = (function() {

    __extends(Router, Backbone.Router);

    function Router() {
      Router.__super__.constructor.apply(this, arguments);
    }

    Router.prototype.routes = {
      '': 'loop',
      'ads': 'ads',
      'check-ins': 'check_ins',
      'images': 'images',
      'tweets': 'tweets',
      'loop': 'loop'
    };

    Router.prototype.ads = function() {
      return ads.fetch();
    };

    Router.prototype.check_ins = function() {
      return check_ins.fetch();
    };

    Router.prototype.images = function() {
      return images.fetch();
    };

    Router.prototype.tweets = function() {
      return tweets.fetch();
    };

    Router.prototype.loop = function() {
      return new PresentationLoop(12000);
    };

    return Router;

  })();

  window.Ad = (function() {

    __extends(Ad, Backbone.Model);

    function Ad() {
      Ad.__super__.constructor.apply(this, arguments);
    }

    return Ad;

  })();

  window.CheckIn = (function() {

    __extends(CheckIn, Backbone.Model);

    function CheckIn() {
      CheckIn.__super__.constructor.apply(this, arguments);
    }

    return CheckIn;

  })();

  window.Image = (function() {

    __extends(Image, Backbone.Model);

    function Image() {
      Image.__super__.constructor.apply(this, arguments);
    }

    return Image;

  })();

  window.Tweet = (function() {

    __extends(Tweet, Backbone.Model);

    function Tweet() {
      Tweet.__super__.constructor.apply(this, arguments);
    }

    Tweet.prototype.initialize = function(attrs) {
      if (attrs.text) {
        return this.set({
          html: this.htmlDecode(attrs.text)
        }, {
          silent: true
        });
      }
    };

    Tweet.prototype.htmlDecode = function(value) {
      return $('<div/>').html(value).text();
    };

    return Tweet;

  })();

  window.Ads = (function() {

    __extends(Ads, Backbone.Collection);

    function Ads() {
      Ads.__super__.constructor.apply(this, arguments);
    }

    Ads.prototype.model = Ad;

    Ads.prototype.url = 'http://assets.athega.se/jullunch/ads.json';

    return Ads;

  })();

  window.CheckIns = (function() {

    __extends(CheckIns, Backbone.Collection);

    function CheckIns() {
      CheckIns.__super__.constructor.apply(this, arguments);
    }

    CheckIns.prototype.model = CheckIn;

    CheckIns.prototype.url = '/data/latest_check_ins.json';

    return CheckIns;

  })();

  window.Images = (function() {

    __extends(Images, Backbone.Collection);

    function Images() {
      Images.__super__.constructor.apply(this, arguments);
    }

    Images.prototype.model = Image;

    Images.prototype.url = 'http://assets.athega.se/jullunch/latest_images.json?' + tick();

    return Images;

  })();

  window.Tweets = (function() {

    __extends(Tweets, Backbone.Collection);

    function Tweets() {
      Tweets.__super__.constructor.apply(this, arguments);
    }

    Tweets.prototype.model = Tweet;

    Tweets.prototype.url = 'http://assets.athega.se/jullunch/tweets.json';

    return Tweets;

  })();

  window.PresentationLoop = (function() {

    function PresentationLoop(ms) {
      this.delay = ms;
      this.iteration = 0;
      window.loop = this;
      window.loop.run();
    }

    PresentationLoop.prototype.tweets = function() {
      tweets.fetch();
      setTimeout('tweets.fetch()', this.delay / 2);
      return setTimeout('window.loop.check_ins()', this.delay);
    };

    PresentationLoop.prototype.check_ins = function() {
      check_ins.fetch();
      return setTimeout('window.loop.images()', this.delay);
    };

    PresentationLoop.prototype.images = function() {
      images.fetch();
      setTimeout('images.fetch()', this.delay / 2);
      return setTimeout('window.loop.ads()', this.delay);
    };

    PresentationLoop.prototype.ads = function() {
      ads.fetch();
      return setTimeout('window.loop.iterate()', this.delay);
    };

    PresentationLoop.prototype.iterate = function() {
      this.iteration += 1;
      console.log('iteration: ' + this.iteration);
      return setTimeout('window.loop.tweets()', 0);
    };

    PresentationLoop.prototype.run = function() {
      var _this = this;
      return setTimeout((function() {
        return _this.tweets();
      }), 0);
    };

    return PresentationLoop;

  })();

  window.app = {};

  app.views = {};

  $(function() {
    if (navigator.platform.indexOf("iPad") !== -1) {
      $(document).bind('touchmove', function(e) {
        return e.preventDefault();
      });
    }
    window.ads = new Ads();
    window.check_ins = new CheckIns();
    window.images = new Images();
    window.tweets = new Tweets();
    app.router = new Router();
    app.views.ads = new AdsView({
      collection: ads
    });
    app.views.check_ins = new CheckInsView({
      collection: check_ins
    });
    app.views.images = new ImagesView({
      collection: images
    });
    app.views.tweets = new TweetsView({
      collection: tweets
    });
    return Backbone.history.start({
      pushState: true
    });
  });

}).call(this);
