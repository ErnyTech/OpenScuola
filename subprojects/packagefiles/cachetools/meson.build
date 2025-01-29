project('cachetools', 'd',
    meson_version: '>=0.46',
    license: 'BSL-1.0',
    version: '0.3.1'
)

#
# Sources
#
cachetools_src = [
    'source/cachetools/cache.d',
    'source/cachetools/cache2q.d',
    'source/cachetools/cachelru.d',
    'source/cachetools/hash.d',
    'source/cachetools/interfaces.d',
    'source/cachetools/internal.d',
    'source/cachetools/package.d',
    'source/cachetools/containers/hashmap.d',
    'source/cachetools/containers/lists.d',
    'source/cachetools/containers/orderedhashmap.d',
    'source/cachetools/containers/package.d',
    'source/cachetools/containers/set.d',
]

source_dir = include_directories('source/')

#
# Targets
#
cachetools_libshared = shared_library('cachetools',
        [cachetools_src],
        include_directories: [source_dir]
)

cachetools_libstatic = static_library('cachetools',
        [cachetools_src],
        include_directories: [source_dir]
)

pkgc = import('pkgconfig')
pkgc.generate(name: 'cachetools',
              libraries: [cachetools_libshared, cachetools_libstatic],
              subdirs: 'd/cachetools',
              version: meson.project_version(),
              description: 'Collection of cache strategies'
)

# for use by others which embed this as subproject
cachetools_shared_dep = declare_dependency(
    link_with: [cachetools_libshared],
    include_directories: [source_dir],
)

cachetools_static_dep = declare_dependency(
    link_with: [cachetools_libstatic],
    include_directories: [source_dir],
)
