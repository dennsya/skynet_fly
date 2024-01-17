local rax = require "rax"
local utils = require "benchmark.utils"

local route_n = os.getenv("RADIX_ROUTER_ROUTES") or 1000 * 100
local times = os.getenv("RADIX_ROUTER_TIMES") or 1000 * 1000

local router
do
   router = rax:new()
  local routes = {}
  for i = 1, route_n do
    router:insert("GET", string.format("/%d/*path", i), i)
  end
  router:compile()
end

local rss_mb = utils.get_rss()

local path = "/1/a"
local elapsed = utils.timing(function()
  for _ = 1, times do
    router:match(path, "GET")
  end
end)

utils.print_result({
  title = "rax prefix",
  routes = route_n,
  times = times,
  elapsed = elapsed,
  benchmark_path = path,
  benchmark_handler = router:match(path),
  rss = rss_mb,
})
