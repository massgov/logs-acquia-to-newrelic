FROM php:7.4-cli
COPY . /usr/src/myapp
WORKDIR /usr/src/myapp
RUN composer install
CMD [ "php", "./index.php", "mass:logstream", "--logtypes=varnish-request" ]