var gulp = require('gulp');
var browserify = require('browserify');
var source = require('vinyl-source-stream');
var minifyCSS =require('gulp-minify-css');
var rename = require('gulp-rename');
var uglify = require('gulp-uglify');
var del = require('del');
var sass = require('gulp-sass');


gulp.task('deleteSass', function(){
	del(['css/customSassTheme.css'], function(err){
		console.log('file deleted');
	})
});


gulp.task('sass', function () {
  gulp.src('customSassTheme/*.scss')
    .pipe(sass({indentedSyntax: false}))
    .pipe(gulp.dest('css/customSassTheme.css'))
});



gulp.task('delete', function(){
	del(['css/application.min.css'], function(err){
		console.log('file deleted');
	})
});


gulp.task('style', function(){
	return gulp
	.src('css/application.css')
	.pipe(minifyCSS({keepBreaks: true}))
    .pipe(rename({suffix: '.min'}))
	.pipe(gulp.dest('css'));
});

gulp.task('sassDel', ['deleteSass','sass']);

gulp.task('default', ['delete','style']);