{join, normalize, resolve, extname, dirname, basename} = require('path')

isAbsolute = (path) -> /^\//.test(path)
isRelative = (path) -> /^\.\//.test(path)
isPackage  = (path) -> not /\//.test(path)

# Normalize paths and remove extensions
# to create valid CommonJS modue names
namify = (path) -> 
  path = normalize(path)
  ext  = extname(path)
  join(dirname(path), basename(path, ext))

# Check to see if there's a more appropriate 
# browser specific file to use when loading packages
getPackagePath = (path) ->
  try
    package = require.resolve(join(path, 'package.json'))
    package = JSON.parse(fs.readFileSync(package))
    path = package.browser or package.browserify or package.main
    throw("Invalid package #{package}") unless path
    path
  catch e

# Resolves a `require()` call. Pass in the name of the module where
# the call was made, and the path that was required. 
# Returns an array of: [moduleName, scriptPath]
# 
#   resolve('lib/init', 'spine') #=> ['spine', '/path/to/spine.js']
# 
module.exports = (name, path) ->
  throw 'Path required' unless path
  if isAbsolute(path)      
    # Matches: "/spine.ajax"
    # Returns: [/spine.ajax, /spine.ajax.js]
    [namify(path), require.resolve(path)]
  else if isRelative(path) 
    # Matches: "./spine.ajax"
    # Returns: [spine/spine.ajax, /path/spine/spine.ajax.js]
    name = dirname(name)
    [namify(join(name, path)), require.resolve(join(resolve(name), path))]
  else if isPackage(path)
    # Matches: "spine"
    # Returns: [spine, /path/spine/spine.js]
    [path, require.resolve(join(path, getPackagePath(path)))]
  else
    # Matches: "spine/spine.ajax"
    # Returns: [spine/spine.ajax, /path/spine/spine.ajax.js]
    [path.split('/')[0], require.resolve(path)]