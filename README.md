# Honcho

*Honcho is a Sidekiq- and Resque-aware process manager.*

**Note: I didn't realize when I made this that there was already [Honcho](https://github.com/nickstenning/honcho),
a clone of Foreman in Python. Sorry for the confusion. I might end up renaming this.**

You can use it in place of Foreman if you need to manage several instances
of Sidekiq and/or Resque and don't necessarily need them all to run at once.

## Why?

We have a dozen apps all running Sidekiq (and some running Resque). In development,
I don't need/want all of them running at once, so I built this.

This might be super useful if you are using Vagrant or VM for development
and want to limit its RAM usage.

**This is probably not useful in a production environment.** But, let me know
if you think it is!

## Features

* Watches Redis and only starts Sidekiq/Resque processes when there is work to be done
* Spins down inactive Sidekiq/Resque processes
* Sends TERM signal to child processes so they shut down properly
* Saves memory

## Configure and Run

Honcho is configured with a `honcho.yml` file like this:

```yaml
command_template: "bash -c \"eval \\\"\\$(rbenv init -)\\\" && rbenv shell \\$(cat .ruby-version) && %s\""
apps:
  check-ins:
    path: ../check-ins
    sidekiq:
      namespace: check-ins-sidekiq-development
      command: bundle exec sidekiq
  services:
    path: ../services
    resque:
      namespace: planning_center_development
      command: bundle exec resque-pool --environment development
    sidekiq:
      namespace: services-development.sidekiq
      command: bundle exec sidekiq
```

`namespace` is the Redis namespace to monitor for jobs.

Install Honcho:

```
gem install honcho
```

Run Honcho:

```
honcho
```

# To Do

- [ ] make the command template configurable via the command line
- [x] allow specifying path to config file via command line
- [ ] maybe autodetect rbenv and simplify the `command_template` as a result

# Copyright

Copyright Tim Morgan, Licensed MIT.
