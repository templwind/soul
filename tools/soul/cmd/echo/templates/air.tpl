root = "."
tmp_dir = "tmp"

[build]
args_bin = ["serve"]
bin = "./tmp/{{.serviceName}}"
cmd = "make build"
delay = 1000
exclude_dir = ["assets", "tmp", "vendor"]
exclude_file = []
exclude_regex = [".*_templ.go"]
exclude_unchanged = false
follow_symlink = false
full_bin = ""
include_dir = []
include_ext = [
  "css",
  "env",
  "go",
  "html",
  "js",
  "sql",
  "templ",
  "tmpl",
  "tpl",
  "ts",
  "yaml",
  "yml",
]
kill_delay = "0s"
log = "build-errors.log"
send_interrupt = false
stop_on_error = true

[color]
app = ""
build = "yellow"
main = "magenta"
runner = "green"
watcher = "cyan"

[log]
time = false

[misc]
clean_on_exit = false
