environment 'production'
pidfile "tmp/puma/pid"
state_path "tmp/puma/state"
bind 'unix:///tmp/kipketer.sock'
activate_control_app
stdout_redirect 'log/stdout', 'log/stderr', true

workers 4 # We start four workers to ensure streaming.
