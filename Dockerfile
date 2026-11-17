FROM php:8.3.36-cli
COPY . /usr/src/myapp
WORKDIR /usr/src/myapp
RUN apt-get update && apt-get install -y libzip-dev zip && docker-php-ext-install zip
COPY --from=composer:2.10.3 /usr/bin/composer /usr/bin/composer
RUN composer install
CMD [ "php", "./index.php", "mass:logstream" ]
