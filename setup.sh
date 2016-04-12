#!/usr/bin/env bash
setup_laravel() {
cd /var/www/html/$1
mysql -uroot -ptieungao -e "create database $1;"
sed -i -e "s/DB_DATABASE=homestead/DB_DATABASE=$1/g" .env
composer install

php artisan key:generate
php artisan migrate
php artisan ide-helper:generate

chmod -R 777 storage
chmod -R 777 bootstrap
php artisan vendor:publish --provider="Intervention\Image\ImageServiceProviderLaravel5"
php artisan vendor:publish
cd /var/www/html/$1
}

setup_editor() {
cd /var/www/html/$1
[ -d public/upload ] || mkdir public/upload
[ -d public/files ] || mkdir public/files
chmod -R 777 public/upload
chmod -R 777 public/files

cd public && bower install && [ -d kcfinder ] || git clone git@github.com:sunhater/kcfinder.git
sed -i  "s/'disabled' => true/'disabled' => false/g" kcfinder/conf/config.php
sed -i  's/"upload"/"\/upload"/g' kcfinder/conf/config.php
[ -d bower_components/ckeditor/plugins/pbckcode ] || git clone git@github.com:prbaron/pbckcode.git bower_components/ckeditor/plugins/pbckcode

cat > bower_components/ckeditor/config.js  <<'endmsg'
CKEDITOR.editorConfig = function( config ) {
	// Define changes to default configuration here. For example:
	config.filebrowserBrowseUrl = '/kcfinder/browse.php?opener=ckeditor&type=files';
	config.filebrowserImageBrowseUrl = '/kcfinder/browse.php?opener=ckeditor&type=images';
	config.filebrowserFlashBrowseUrl = '/kcfinder/browse.php?opener=ckeditor&type=flash';
	config.filebrowserUploadUrl = '/kcfinder/upload.php?opener=ckeditor&type=files';
	config.filebrowserImageUploadUrl = '/kcfinder/upload.php?opener=ckeditor&type=images';
	config.filebrowserFlashUploadUrl = '/kcfinder/upload.php?opener=ckeditor&type=flash';
	//do not add extra paragraph to html
	config.autoParagraph = false;

	config.toolbarGroups = [
		{"name":"basicstyles","groups":["basicstyles"]},
		{"name":"links","groups":["links"]},
		{"name":"paragraph","groups":["list","blocks"]},
		{"name":"document","groups":["mode"]},
		{"name":"insert","groups":["insert"]},
		{"name":"styles","groups":["styles"]},
		{"name":"about","groups":["about"]},
		{ name: 'pbckcode', "groups":["pbckcode"]}
	];

	config.extraPlugins = 'pbckcode';
};
endmsg
cd /var/www/html/$1
}

echo "Start setup..."

cp .env.stage .env
read -p "Your project : "  project
setup_laravel $project
setup_editor $project







