module.exports = function(grunt) {

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),

        inline: {
            dist: {
                options: {
                    tag: ''
                },
                src: 'build/index-tidied.html',
                dest: 'build/index-inlined.html'
            }
        },

        uncss: {
            dist: {
                files: {
                    'build/css/tidy.css': ['build/index.html']
                }
            }
        },

        processhtml: {
            dist: {
                files: {
                    'build/index-tidied.html': ['build/index.html']
                }
            }
        },

        es6transpiler: {
            dist: {
                files: {
                    'build/js/manager-es5.js': 'build/js/manager-loaded.js'
                }
            }
        },

        uglify: {
            dist: {
                files: {
                    'build/js/manager.min.js': ['build/js/manager-es5.js']
                }
            }
        },

        htmlmin: {
            dist: {
                options: {
                    removeComments: true,
                    collapseWhitespace: true,
                    minifyCSS: true
                },
                files: {
                    'index.html': 'build/index-inlined.html'
                }
            }
        },

        manifest: {
            generate: {
                options: {
                    basePath: './',
                    cache: [],
                    network: ['http://*', 'https://*'],
                    fallback: [],
                    exclude: [],
                    preferOnline: true,
                    verbose: false,
                    timestamp: true,
                    hash: false,
                    master: ['index.html']
                },
                src: [
                    'index.html'
                ],
                dest: 'manifest.appcache'
            }
        },

        copy: {
            dist: {
                files: [
                    {
                        expand: true,
                        cwd: 'assets/',
                        src: ['**'],
                        dest: 'build/'
                    }
                ]
            }
        },

        clean: ['build'],

        watch: {
            src: {
                files: ['assets/**', 'config.json'],
                tasks: ['default'],
                options: {
                    debounceDelay: 2500
                }
            }
        },

        config: {
            basic: {
                options: {
                    namespace: 'export const config'
                },
                src: 'config.json',
                dest: 'build/js/config.js'
            }
        }
    });

    grunt.registerTask('load-js-modules', 'Bundles the es6 modules', function() {
        var transpiler = require('es6-module-transpiler');
        var Container = transpiler.Container;
        var FileResolver = transpiler.FileResolver;
        var BundleFormatter = transpiler.formatters.bundle;

        var container = new Container({
            resolvers: [new FileResolver(['build/js'])],
            formatter: new BundleFormatter()
        });

        container.getModule('manager');
        container.write('build/js/manager-loaded.js');
    });

    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-uncss');
    grunt.loadNpmTasks('grunt-inline-alt');
    grunt.loadNpmTasks('grunt-processhtml');
    grunt.loadNpmTasks('grunt-es6-transpiler');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-htmlmin');
    grunt.loadNpmTasks('grunt-manifest');
    grunt.loadNpmTasks('grunt-global-config');

    // Default task(s).
    grunt.registerTask('default', [
        'clean',
        'copy',
        'config',
        'load-js-modules',
        'es6transpiler',
        'uglify',
        'uncss',
        'processhtml',
        'inline',
        'htmlmin',
        'manifest'
    ]);

};
