# Meson file for OpenScuola CLI

cli_link_args = []
cli_dependencies = []

if get_option('static_cli').enabled() or host_machine.system() == 'windows'
  cli_dependencies += openscuola_bridge_static_dep
  cli_link_args += '-link-defaultlib-shared=false'
else
  cli_dependencies += openscuola_bridge_dep
endif


openscuola_cli = executable('openscuola-cli',
  'cli.d',
  install: true,
  link_args: cli_link_args,
  dependencies: cli_dependencies
)
