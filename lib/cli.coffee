VinePosts = require './'
packageInfo = require '../package'
ArgumentParser = require('argparse').ArgumentParser
JSONStream = require 'JSONStream'

argparser = new ArgumentParser(
  version: packageInfo.version
  addHelp: true
  description: packageInfo.description
)
argparser.addArgument(
  ['--username', '-u']
  type: 'string'
  help: 'Username of the account to scrape. Within Vine.co, this is referred to
  as the userId, and is an integer with about 18 digits.'
  required: true
)

argv = argparser.parseArgs()
(new VinePosts(argv.username)).pipe(
  JSONStream.stringify('[', ',\n', ']\n')
).pipe(process.stdout)
