module.exports = (grunt) ->
	grunt.loadNpmTasks 'grunt-browserify'
	grunt.loadNpmTasks 'grunt-contrib-clean'

	grunt.initConfig
		clean: ['dist']
		browserify:
			dist:
				files:
					'dist/chronicler.js': ['src/**/*.coffee']
				options:
					transform: ['coffeeify']

	grunt.registerTask 'build', ['clean','browserify']
