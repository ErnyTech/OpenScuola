project('dlang-requests', 'd',
    meson_version: '>=0.46',
    license: 'BSL-1.0',
    version: '1.0.0',
)

project_soversion = '1'
cachetools = subproject('cachetools')

#
# Sources
#
requests_src = [
    'source/requests/pool.d',
    'source/requests/uri.d',
    'source/requests/ssl_adapter.d',
    'source/requests/http.d',
    'source/requests/utils.d',
    'source/requests/ftp.d',
    'source/requests/package.d',
    'source/requests/request.d',
    'source/requests/idna/punycode/codec.d',
    'source/requests/idna/punycode/package.d',
    'source/requests/idna/package.d',
    'source/requests/server/httpd.d',
    'source/requests/server/package.d',
    'source/requests/streams.d',
    'source/requests/connmanager.d',
    'source/requests/rangeadapter.d',
    'source/requests/base.d'
]

src_dir = include_directories('source/')
#
# Targets
#

if host_machine.system() != 'windows'
	dlang_requests_sharedlib = shared_library('dlang-requests',
        	[requests_src],
       		include_directories: src_dir,
        	install: true,
        	version: meson.project_version(),
        	soversion: project_soversion,
        	d_module_versions: ['std'],
        	dependencies: [cachetools.get_variable('cachetools_shared_dep')]
	)
endif

dlang_requests_staticlib = static_library('dlang-requests',
        [requests_src],
        include_directories: src_dir,
        install: true,
        d_module_versions: ['std'],
        dependencies: [cachetools.get_variable('cachetools_static_dep')]
)

test_exe = executable('drequests_test',
    [requests_src,
     'tests/httpbin.d',
     'tests/app.d'],
    include_directories: [src_dir, include_directories('tests/')],
    d_unittest: true,
    d_module_versions: ['std', 'httpbin', 'unittest_fakemain'],
    dependencies: [cachetools.get_variable('cachetools_static_dep')]
)
test('drequests_test', test_exe, workdir : meson.current_source_dir())

if host_machine.system() != 'windows'
	pkgc = import('pkgconfig')
	pkgc.generate(dlang_requests_sharedlib,
              	name: 'dlang-requests',
              	libraries: [dlang_requests_sharedlib, dlang_requests_staticlib],
              	subdirs: 'd/requests',
              	version: meson.project_version(),
              	description: 'D HTTP client library inspired by python-requests.',
              	d_module_versions: ['std']
	)

# to allow others to easily use this as a subproject
	dlang_requests_dep = declare_dependency(
    	link_with: [dlang_requests_sharedlib],
    	include_directories: [src_dir],
    	dependencies: [cachetools.get_variable('cachetools_shared_dep')]
	)
endif

dlang_requests_static_dep = declare_dependency(
    link_with: [dlang_requests_staticlib],
    include_directories: [src_dir],
    dependencies: [cachetools.get_variable('cachetools_static_dep')]
)

#
# Install
#
install_subdir('source/requests/', install_dir: 'include/d/requests/')
