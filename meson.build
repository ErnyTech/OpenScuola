project('openscuola', 'd',
  version: '0.1'
)

assert(meson.get_compiler('d').get_id() == 'llvm', 'This project only support the LDC D compiler.')

openscuola_bridge_headers = [
  'include/openscuola/bridge/deviceId.di',
  'include/openscuola/bridge/deviceId.h',
  'include/openscuola/bridge/downloadbook.di',
  'include/openscuola/bridge/downloadbook.h',
  'include/openscuola/bridge/history.di',
  'include/openscuola/bridge/history.h',
  'include/openscuola/bridge/login.di',
  'include/openscuola/bridge/login.h',
  'include/openscuola/bridge/util.di',
  'include/openscuola/bridge/util.h',
]

openscuola_bridge_files = [
  'lib/openscuola/bridge/deviceId.d',
  'lib/openscuola/bridge/downloadbook.d',
  'lib/openscuola/bridge/drm.d',
  'lib/openscuola/bridge/history.d',
  'lib/openscuola/bridge/login.d',
  'lib/openscuola/bridge/util.d'
]

openscuola_bridge_to_dinterface = [
  'lib/openscuola/bridge/deviceId.d',
  'lib/openscuola/bridge/downloadbook.d',
  'lib/openscuola/bridge/history.d',
  'lib/openscuola/bridge/login.d',
  'lib/openscuola/bridge/util.d',
]

libshared_dependencies = []
libstatic_dependencies = []
pkg_libs = []

dlang_requests = subproject('dlang_requests')
dxml = subproject('dxml')

if host_machine.system() != 'windows'
  libshared_dependencies += dlang_requests.get_variable('dlang_requests_dep')
  libshared_dependencies += dxml.get_variable('dxml_shared_dep')
endif

libstatic_dependencies += dlang_requests.get_variable('dlang_requests_static_dep')
libstatic_dependencies += dxml.get_variable('dxml_static_dep')

ldc_prog = find_program('ldc2')

message('Generating D interfaces...')
dinterface_gen = run_command(ldc_prog,
    '-Hd=include/openscuola/bridge', '--o-',
    '-J=' + meson.current_source_dir(),
    '-I', 'lib',
    '-I', 'subprojects/dxml/source',
    '-I', 'subprojects/dlang_requests/source', 
    '-I', 'subprojects/cachetools/source',
    openscuola_bridge_to_dinterface,
    check: true
)

if dinterface_gen.returncode() != 0
    error('Unable to build D interfaces:\n' + dinterface_gen.stderr())
endif

if host_machine.system() != 'windows'
  openscuola_bridge_shared = shared_library('openscuola-bridge',
      openscuola_bridge_files,
      install: true,
      include_directories: 'lib',
      d_args: ['-J=' + meson.current_source_dir()],
      dependencies: libshared_dependencies
  )

  openscuola_bridge_dep = declare_dependency(
    include_directories: 'include',
    link_with : openscuola_bridge_shared
  )

  pkg_libs += openscuola_bridge_shared
endif

openscuola_bridge_static = static_library('openscuola-bridge',
    openscuola_bridge_files,
    install: true,
    include_directories: 'lib',
    d_args: ['-J=' + meson.current_source_dir()],
    dependencies: libstatic_dependencies
)

openscuola_bridge_static_dep = declare_dependency(
  include_directories: 'include',
  link_with : openscuola_bridge_static
)

pkg_libs += openscuola_bridge_static

install_headers(openscuola_bridge_headers, subdir : 'openscuola/bridge')

pkg_mod = import('pkgconfig')
pkg_mod.generate(
  name : meson.project_name() + '-bridge',
  filebase : meson.project_name() + '-bridge',
  description : 'A convenient bridge to ScuolaBook.',
  subdirs : 'openscuola/bridge',
  libraries : pkg_libs
)

# OpenScuola CLI
if get_option('cli').enabled()
  subdir('cli/')
endif