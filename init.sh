#!/usr/bin/env bash

 init_composer() {
cd /var/www/html/
~/.composer/vendor/bin/laravel new $1
cd $1
composer require barryvdh/laravel-ide-helper
composer require laracasts/flash
composer require intervention/image
composer require intervention/imagecache
composer require cviebrock/eloquent-sluggable
composer require laravelcollective/html

#addd to config/app.php


sed -i "/'providers' =>/a \\\t\\tBarryvdh\\\LaravelIdeHelper\\\IdeHelperServiceProvider::class," config/app.php
sed -i "/'providers' =>/a \\\t\\tLaracasts\\\Flash\\\FlashServiceProvider::class," config/app.php
sed -i "/'providers' =>/a \\\t\\tIntervention\\\Image\\\ImageServiceProvider::class," config/app.php
sed -i "/'providers' =>/a \\\t\\tCviebrock\\\EloquentSluggable\\\SluggableServiceProvider::class," config/app.php
sed -i "/'providers' =>/a \\\t\\tCollective\\\Html\\\HtmlServiceProvider::class," config/app.php

sed -i "/'aliases' =>/a \\\t\\t'Flash'     => Laracasts\\\Flash\\\Flash::class," config/app.php
sed -i "/'aliases' =>/a \\\t\\t'Image'     => Intervention\\\Image\\\Facades\\\Image::class," config/app.php
sed -i "/'aliases' =>/a \\\t\\t'Form'      => Collective\\\Html\\\FormFacade::class," config/app.php
sed -i "/'aliases' =>/a \\\t\\t'Html'      => Collective\\\Html\\\HtmlFacade::class," config/app.php

#create view composer
php artisan make:provider ViewComposerProvider
sed -i "/'providers' =>/a \\\t\\tApp\\\Providers\\\ViewComposerProvider::class," config/app.php

php artisan ide-helper:generate

cat > .gitignore <<'endmsg'
/vendor
.env
.idea
_ide_helper.php
/public/upload
/public/files/*
/public/bower_components
/public/kcfinder
endmsg
php artisan vendor:publish --provider="Intervention\Image\ImageServiceProviderLaravel5"
php artisan vendor:publish

cd /var/www/html/$1
}

setup_laravel() {
cd /var/www/html/$1
mysql -uroot -ptieungao -e "create database $1;"
sed -i -e "s/DB_HOST=127.0.0.1/DB_HOST=localhost/g" .env
sed -i -e "s/DB_DATABASE=homestead/DB_DATABASE=$1/g" .env
sed -i -e "s/DB_USERNAME=homestead/DB_USERNAME=root/g" .env
sed -i -e "s/DB_PASSWORD=secret/DB_PASSWORD=tieungao/g" .env

chmod -R 777 storage
chmod -R 777 bootstrap

php artisan migrate
cd /var/www/html/$1
}

install_editor() {
cd /var/www/html/$1
[ -d public/upload ] || mkdir public/upload
[ -d public/files ] || mkdir public/files
chmod -R 777 public/upload
chmod -R 777 public/files

cd public
cat > bower.json  <<'endmsg'
{
  "name": "public",
  "homepage": "https://github.com/thienkimlove",
  "authors": [
    "Quan Do <thienkimlove@gmail.com>"
  ],
  "description": "",
  "main": "",
  "moduleType": [],
  "license": "MIT",
  "ignore": [
    "**/.*",
    "node_modules",
    "bower_components",
    "test",
    "tests"
  ],
  "dependencies": {
    "ckeditor": "#standard/latest"
  }
}
endmsg
bower install
[ -d kcfinder ] || git clone git@github.com:sunhater/kcfinder.git
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

string_replace() {
    echo "${1/\*/$2}"
}

project_setup() {
cd /var/www/html/$1
  echo >> app/Http/routes.php <<'endmsg'
  Route::get('example/composer', function(){
    return view('example.composer');
});

Route::get('example/paginator', function(){
    $posts = \App\Post::paginate(1);
    //$posts->setPath('custom/url');
    return view('example.paginator', compact('posts'));
});


Route::get('restricted', function(){
    return view('errors.restricted');
});

Route::group(['middleware' => 'web'], function () {
    Route::auth();

    Route::get('/admin', 'HomeController@index');
    Route::resource('admin/posts', 'PostsController');
    Route::resource('admin/categories', 'CategoriesController');
    Route::resource('admin/settings', 'SettingsController');
});

endmsg

}

migration_create() {
migration_categories=$(php artisan make:migration create_categories_table --create=categories)
migration_categories=$(echo $migration_categories | sed 's/Created Migration: //g').php

sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->string('name');" database/migrations/$migration_categories
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->integer('parent_id')->nullable()->index();" database/migrations/$migration_categories
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->string('slug', 200)->unique();" database/migrations/$migration_categories

migration_posts=$(php artisan make:migration create_posts_table --create=posts)
migration_posts=$(echo $migration_posts | sed 's/Created Migration: //g').php

sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->string('title');" database/migrations/$migration_posts
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->string('slug', 200)->unique();" database/migrations/$migration_posts
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->integer('category_id')->unsigned();" database/migrations/$migration_posts
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->foreign('category_id')->references('id')->on('categories')->onDelete('cascade');" database/migrations/$migration_posts
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->text('desc');" database/migrations/$migration_posts
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->text('content');" database/migrations/$migration_posts
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->string('image')->nullable()->default(null);" database/migrations/$migration_posts
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->boolean('status')->default(true);" database/migrations/$migration_posts


migration_tags=$(php artisan make:migration create_tags_table --create=tags)
migration_tags=$(echo $migration_tags | sed 's/Created Migration: //g').php

echo > database/migrations/$migration_tags <<'endmsg'
<?php

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateTagsTable extends Migration {

    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tags', function(Blueprint $table)
        {
            $table->increments('id');
            $table->string('name');
            $table->string('slug', 200)->unique();
            $table->timestamps();
        });
        Schema::create('post_tag', function(Blueprint $tale)
        {
            $tale->integer('post_id')->unsigned()->index();
            $tale->foreign('post_id')->references('id')->on('posts')->onDelete('cascade');
            $tale->integer('tag_id')->unsigned()->index();
            $tale->foreign('tag_id')->references('id')->on('tags')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::drop('post_tag');
        Schema::drop('tags');
    }

}

endmsg

migration_settings=$(php artisan make:migration create_settings_table --create=settings)
migration_settings=$(echo $migration_settings | sed 's/Created Migration: //g').php

sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->string('name')->unique();" database/migrations/$migration_settings
sed -i "/\$table->increments('id')/a \\\t\\t\\t \$table->text('value');" database/migrations/$migration_settings

php artisan migrate

}

echo "Start setup..."
cd /var/www/html/vitamin
read -p "Project Identify : "  project
#init_composer $project
#setup_laravel $project
#install_editor $project
#migration_create