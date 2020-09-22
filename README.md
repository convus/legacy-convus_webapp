# Welcome to Convus <img src="icon.png" height="40">

This is the [Convus web app](https://www.convus.org)

### Dependencies

_We recommend [asdf-vm](https://asdf-vm.com/#/) for managing versions of Ruby and Node. Check the [.tool-versions](.tool-versions) file to see the versions of the following dependencies that Convus uses._

- [Ruby](http://www.ruby-lang.org/en/)

- [Rails](http://rubyonrails.org/)

- [Node](https://nodejs.org/en/) & [yarn](https://yarnpkg.com/en/)

- PostgreSQL

- [Redis](http://redis.io/)

## Running locally

This explanation assumes you're familiar with developing Ruby on Rails applications.

- `bundle install && yarn install` to install the dependencies

- `bin/rake db:create db:migrate db:test:prepare` to setup the database

- `cp .env .env.development` and fill in the values for your [GitHub OAuth application](https://github.com/settings/applications/new) in the new `.env.development` file (required for authentication)

- `./start` start the server.

  - [start](start) is a bash script. It starts redis in the background and runs foreman with the [dev procfile](Procfile_development). If you need/prefer something else, do that. If your "something else" isn't running at localhost:4242, change the appropriate values in [Procfile_development](Procfile_development) and [.env](.env)

- Go to [localhost:4242](http://localhost:4242)

---

The source code for [convus_webapp](https://github.com/convus/convus_webapp) is licensed under [AGPL-3.0](https://github.com/convus/convus_webapp/blob/main/LICENSE).
