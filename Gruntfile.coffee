module.exports = (grunt) ->
	grunt.loadNpmTasks 'grunt-browserify'
	grunt.loadNpmTasks 'grunt-contrib-clean'
	grunt.loadNpmTasks 'grunt-contrib-watch'

	grunt.initConfig
		clean: ['dist']
		browserify:
			dist:
				files:
					'dist/chronicler.js': ['src/**/*.coffee']
				options:
					transform: ['coffeeify']
		watch:
			scripts:
				files: ['src/**/*.coffee']
				tasks: ['browserify']

	grunt.registerTask 'build', ['clean','browserify', 'watch:scripts']
