# Build and test PHP applications with Gitlab CI (or any other CI platform)

> Docker images with everything you'll need to build and test PHP applications.

![Logo](https://raw.githubusercontent.com/mallardduck/gitlab-ci-pipeline-php/main/gitlab-ci-pipeline-php.png)

---
![GitHub last commit](https://img.shields.io/github/last-commit/mallardduck/gitlab-ci-pipeline-php.svg?style=for-the-badge&logo=git) [![Docker Pulls](https://img.shields.io/docker/pulls/mallardduck/gitlab-ci-pipeline-php.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/mallardduck/gitlab-ci-pipeline-php/)

---

## Based on [Official PHP images](https://hub.docker.com/_/php/)

> PHP 8.0 & 8.1 available!

- ```8.1```, ```8```, ```latest``` [(8.1/Dockerfile)](https://github.com/mallardduck/gitlab-ci-pipeline-php/blob/main/php/8.1/Dockerfile) - [![](https://images.microbadger.com/badges/image/mallardduck/gitlab-ci-pipeline-php:8.1.svg)](https://microbadger.com/images/mallardduck/gitlab-ci-pipeline-php:8.1 "Get your own image badge on microbadger.com")

- ```8.1-alpine```, ```alpine``` [(8.1/alpine/Dockerfile)](https://github.com/mallardduck/gitlab-ci-pipeline-php/blob/main/php/8.1/alpine/Dockerfile) - [![](https://images.microbadger.com/badges/image/mallardduck/gitlab-ci-pipeline-php:8.1-alpine.svg)](https://microbadger.com/images/mallardduck/gitlab-ci-pipeline-php:8.1-alpine "Get your own image badge on microbadger.com")

- ```8.1-fpm```, ```fpm``` [(8.1/fpm/Dockerfile)](https://github.com/mallardduck/gitlab-ci-pipeline-php/blob/main/php/8.1/fpm/Dockerfile) - [![](https://images.microbadger.com/badges/image/mallardduck/gitlab-ci-pipeline-php:8.1-fpm.svg)](https://microbadger.com/images/mallardduck/gitlab-ci-pipeline-php:8.1-fpm "Get your own image badge on microbadger.com")

- ```8.0``` [(8.0/Dockerfile)](https://github.com/mallardduck/gitlab-ci-pipeline-php/blob/main/php/8.0/Dockerfile) - [![](https://images.microbadger.com/badges/image/mallardduck/gitlab-ci-pipeline-php:8.0.svg)](https://microbadger.com/images/mallardduck/gitlab-ci-pipeline-php:8.0 "Get your own image badge on microbadger.com")

- ```8.0-alpine``` [(8.0/alpine/Dockerfile)](https://github.com/mallardduck/gitlab-ci-pipeline-php/blob/main/php/8.0/alpine/Dockerfile) - [![](https://images.microbadger.com/badges/image/mallardduck/gitlab-ci-pipeline-php:8.0-alpine.svg)](https://microbadger.com/images/mallardduck/gitlab-ci-pipeline-php:8.0-alpine "Get your own image badge on microbadger.com")

- ```8.0-fpm``` [(8.0/fpm/Dockerfile)](https://github.com/mallardduck/gitlab-ci-pipeline-php/blob/main/php/8.0/fpm/Dockerfile) - [![](https://images.microbadger.com/badges/image/mallardduck/gitlab-ci-pipeline-php:8.0-fpm.svg)](https://microbadger.com/images/mallardduck/gitlab-ci-pipeline-php:8.0-fpm "Get your own image badge on microbadger.com")

All versions come with [Node 14](https://nodejs.org/en/), [Composer](https://getcomposer.org/) and [Yarn](https://yarnpkg.com)

---

## Laravel projects

All images come with PHP (with all laravel required extensions), Composer (with [hirak/prestissimo](https://github.com/hirak/prestissimo) to speed up installs), Node and [Yarn](https://yarnpkg.com).

Everything you need to test Laravel projects :D

### Laravel Dusk

To run Dusk tests we need chromium installed on the image, because of that we have a special tag for this case.

- ```8.1-chromium``` [(8.1/chromium/Dockerfile)](https://github.com/mallardduck/gitlab-ci-pipeline-php/blob/main/php/8.1/chromium/Dockerfile) [![](https://images.microbadger.com/badges/image/mallardduck/gitlab-ci-pipeline-php:8.1-chromium.svg)](https://microbadger.com/images/mallardduck/gitlab-ci-pipeline-php:8.1-chromium "Get your own image badge on microbadger.com")

- ```8.0-chromium``` [(8.0/chromium/Dockerfile)](https://github.com/mallardduck/gitlab-ci-pipeline-php/blob/main/php/8.0/chromium/Dockerfile) [![](https://images.microbadger.com/badges/image/mallardduck/gitlab-ci-pipeline-php:8.0-chromium.svg)](https://microbadger.com/images/mallardduck/gitlab-ci-pipeline-php:8.0-chromium "Get your own image badge on microbadger.com")

Check *Dusk example* for more details.

---

## Gitlab pipeline examples

### Laravel test examples

#### Simple ```.gitlab-ci.yml``` using mysql service

```yaml
# Variables
variables:
  MYSQL_ROOT_PASSWORD: root
  MYSQL_USER: homestead
  MYSQL_PASSWORD: secret
  MYSQL_DATABASE: homestead
  DB_HOST: mysql

test:
  stage: test
  services:
    - mysql:5.7
  image: mallardduck/gitlab-ci-pipeline-php:8.0-alpine
  script:
    - yarn install --pure-lockfile
    - composer install --prefer-dist --no-ansi --no-interaction --no-progress
    - cp .env.example .env
    - php artisan key:generate
    - php artisan migrate:refresh --seed
    - ./vendor/phpunit/phpunit/phpunit -v --coverage-text --colors=never --stderr
```

#### Advanced ```.gitlab-ci.yml``` using mysql service, stages and cache

```yaml
stages:
  - test
  - deploy

# Variables
variables:
  MYSQL_ROOT_PASSWORD: root
  MYSQL_USER: homestead
  MYSQL_PASSWORD: secret
  MYSQL_DATABASE: homestead
  DB_HOST: mysql

# Speed up builds
cache:
  key: $CI_BUILD_REF_NAME # changed to $CI_COMMIT_REF_NAME in Gitlab 9.x
  paths:
    - vendor
    - node_modules
    - public
    - .yarn


test:
  stage: test
  services:
    - mysql:5.7
  image: mallardduck/gitlab-ci-pipeline-php:8.0-alpine
  script:
    - yarn config set cache-folder .yarn
    - yarn install --pure-lockfile
    - composer install --prefer-dist --no-ansi --no-interaction --no-progress
    - cp .env.example .env
    - php artisan key:generate
    - php artisan migrate:refresh --seed
    - ./vendor/phpunit/phpunit/phpunit -v --coverage-text --colors=never --stderr
  artifacts:
    paths:
      - ./storage/logs # for debugging
    expire_in: 7 days
    when: always

deploy:
  stage: deploy
  image: mallardduck/gitlab-ci-pipeline-php:8.0-alpine
  script:
    - echo "Deploy all the things!"
  only:
    - master
  when: on_success
```

#### Laravel Dusk tests ```.gitlab-ci.yml``` using mysql service and cache

```yaml
stages:
  - test

# Variables
variables:
  MYSQL_ROOT_PASSWORD: root
  MYSQL_USER: homestead
  MYSQL_PASSWORD: secret
  MYSQL_DATABASE: homestead
  DB_HOST: mysql

# Speed up builds
cache:
  key: $CI_BUILD_REF_NAME # changed to $CI_COMMIT_REF_NAME in Gitlab 9.x
  paths:
    - vendor
    - node_modules
    - public
    - .yarn


test:
  stage: test
  services:
    - mysql:5.7
  image: mallardduck/gitlab-ci-pipeline-php:8.0-chromium
  script:
    - yarn config set cache-folder .yarn
    - yarn install --pure-lockfile
    - composer install --prefer-dist --no-ansi --no-interaction --no-progress
    - cp .env.example .env
    - php artisan key:generate
    - php artisan migrate:refresh --seed
    - php artisan serve &
    - ./vendor/laravel/dusk/bin/chromedriver-linux --port=9515 &
    - sleep 5
    - php artisan dusk
  artifacts:
    paths:
      - ./storage/logs # for debugging
      - ./tests/Browser/screenshots # for Dusk screenshots
      - ./tests/Browser/console
    expire_in: 7 days
    when: always
```
---

## Deploying Laravel applications with Gitlab

Recommended

- [Deployer](https://deployer.org/blog/how-to-deploy-laravel)
- [Envoyer](https://envoyer.io)

---

Special thanks to [Ambientum](https://github.com/codecasts/ambientum), an incredible Brazilian project, for the inspiration.

[![forthebadge](https://forthebadge.com/images/badges/60-percent-of-the-time-works-every-time.svg)](https://forthebadge.com)
[![forthebadge](https://forthebadge.com/images/badges/contains-cat-gifs.svg)](https://forthebadge.com)
[![forthebadge](http://forthebadge.com/images/badges/built-by-developers.svg)](http://forthebadge.com)
