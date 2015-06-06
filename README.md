# Vine Screen Scrape
[![Build Status](http://img.shields.io/travis/slang800/vine-screen-scrape.svg?style=flat-square)](https://travis-ci.org/slang800/vine-screen-scrape) [![NPM version](http://img.shields.io/npm/v/vine-screen-scrape.svg?style=flat-square)](https://www.npmjs.org/package/vine-screen-scrape) [![NPM license](http://img.shields.io/npm/l/vine-screen-scrape.svg?style=flat-square)](https://www.npmjs.org/package/vine-screen-scrape)

A tool for scraping public data from Vine, without needing to get permission from Vine. It can (theoretically) scrape anything that a non-logged-in user can see. But, right now it only supports getting posts for a given username.

## Example
### CLI
The CLI operates entirely over STDOUT, and will output posts as it scrapes them. The following example is truncated because the output of the real command is obviously very long... it will end with a closing bracket (making it valid JSON) if you see the full output.

```bash
$ vine-screen-scrape -u 969179904094908416
[{"username":"969179904094908416","_id":"1220071062235422720","loop":9,"comment":0,"repost":0,"like":0,"time":1433861823,"text":"test2"},
{"username":"969179904094908416","_id":"1220070436260515840","loop":9,"comment":0,"repost":0,"like":0,"time":1433861673,"text":"test"}]
```

By default, there is 1 line per post, making it easy to pipe into other tools. The following example uses `wc -l` to count how many posts are returned. As you can see, I don't post much.

```bash
$ vine-screen-scrape -u 969179904094908416 | wc -l
2
```

### JavaScript Module
The following example is in CoffeeScript.

```coffee
VinePosts = require 'vine-screen-scrape'

# create the stream
streamOfPosts = new VinePosts('969179904094908416')

# do something interesting with the stream
streamOfPosts.on('readable', ->
  # since it's an object-mode stream, we get objects from it and don't need to
  # parse JSON or anything.
  post = streamOfPosts.read()

  # the time field is represented in UNIX time
  time = new Date(post.time * 1000)

  # output something like "slang800's post from 4/5/2015 got 1 like(s), and 0
  # comment(s)"
  console.log "slang800's post from #{time.toLocaleDateString()} got
  #{post.like} like(s), and #{post.comment} comment(s)"
)
```

The following example is the same as the last one, but in JavaScript.

```js
var scrape, streamOfPosts;
scrape = require('vine-screen-scrape');

streamOfPosts = new VinePosts('969179904094908416');
streamOfPosts.on('readable', function() {
  var post, time;
  post = streamOfPosts.read();
  time = new Date(post.time * 1000);
  console.log([
    "slang800's post from ",
    time.toLocaleDateString(),
    " got ",
    post.like,
    " like(s), and ",
    post.comment,
    " comment(s)"
  ].join(''));
});
```

## Why?
The fact that Vine requires an app to be registered just to access the data that is publicly available on their site is excessively controlling. Scripts should be able to consume the same data as people, and with the same level of authentication. Sadly, Vine doesn't provide an open, structured, and machine readable API.

So, we're forced to use a method that Vine cannot effectively shut down without harming themselves: scraping their user-facing site.

## Caveats
- This is probably against the Vine TOS, so don't use it if that sort of thing worries you.
- Whenever Vine updates certain parts of their front-end this scraper will need to be updated to support the new API.
- You can't scrape protected accounts or get engagement rates / impression counts (cause it's not public duh).
