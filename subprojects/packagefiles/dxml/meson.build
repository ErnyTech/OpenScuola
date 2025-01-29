project('dxml', 'd',
    meson_version: '>=0.46',
    license: 'BSL-1.0',
    version: '0.4.3'
)

#
# Sources
#
dxml_src = [
    'source/dxml/dom.d',
    'source/dxml/internal.d',
    'source/dxml/parser.d',
    'source/dxml/util.d',
    'source/dxml/writer.d'
]

source_dir = include_directories('source/')

#
# Targets
#
dxml_lib = both_libraries('dxml',
        [dxml_src],
        include_directories: [source_dir],
        install: true,
)

pkgc = import('pkgconfig')
pkgc.generate(name: 'dxml',
              libraries: [dxml_lib],
              subdirs: 'd/dxml',
              version: meson.project_version(),
              description: 'An XML parser and writer written in D.'
)

# for use by others which embed this as subproject
dxml_shared_dep = declare_dependency(
    link_with: [dxml_lib.get_shared_lib()],
    include_directories: [source_dir],
)

dxml_static_dep = declare_dependency(
    link_with: [dxml_lib.get_static_lib()],
    include_directories: [source_dir],
)
