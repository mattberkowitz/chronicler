module.exports = (grunt) ->
	grunt.loadNpmTasks 'grunt-browserify'

	grunt.initConfig
		browserify:
			dist:
				files:
					'remington.js': ['src/**/*.coffee']
				options:
					transform: ['coffeeify']

	grunt.registerTask 'build', ['browserify']
