# EventStore + Commanded performance testing based on Conduit
All tests are made on MacBook Pro M1 Max 32GB, PostgreSQL

All dependencies updated to the latest versions, `elixir_uuid` replaced `by uniq`

EventStore set to use 'jsonb' type and JsonbSerializer
Password hashing function replaced 

Project prepared with:

```
mix deps.get
MIX_ENV=prod PORT=4000 mix compile
MIX_ENV=prod PORT=4000 mix reset
```


To discover theoretical performance I will go through the following steps. Each part should be run in production mode:


1. Disable (comment out in the related supervisors) all projectors and workflows except the main one (`Accounts.Projectors.User`)
2. Dispatch commands with eventual consistency only
3. Start the project as `MIX_ENV=prod PORT=4000 iex -S mix phx.server`
4. Create 5000 users by running `Conduit.B.create(5_000)`
5. Get time from the create function ( **718 seconds** )
6. Get time for the User projection ( **00:11:58 or 718 seconds** between the first and the last inserted record timestamp )
7. Reset both databases
8. Create 5_000 users by chunks (10 processes by 500 users) by running `Conduit.B.create_in_parallel(5_000, 500)`
9.  Get the max chunk time from the create function (**555 seconds**)
10. Get time for the User projection (**00:09:14 or 554 seconds** between the max and the min inserted_at record timestamp)
11. Dump eventstore and readstore (Done)
12. Create 100_000 Accounts.ChangeUsername events (10 processes by 10_000 events) by running `Conduit.B.update_usernames_in_parallel(100_000)`
13. Get time from the last chunk of the create function, User aggregates are in-memory currently (**6766 sec or 1 hour 52 min 46 sec**)
14. Get time for the User projection, the difference between min(updated_at) and max(updated_at) where updated_at > max(inserted_at) - **38 min 32 sec**, but the first update (*min(updated_at)*) went into the readstore in **1 hour 15 minutes after** the first UpdateUser command was issued
15. Close Elixir VM, enable Blog.Workflows.CreateAuthorFromUser and Blog.Workflows.ChangeAuthorUsernameFromUser workflows and Blog.Projectors.Author projector, disable Accounts.Projector.Username projection
16. Restore the initial dump (with created users only)
17. Run the project
18. Get time for the Author projection creating 5000 users via CreateAuthorFromUserRegistered workflow, the diff between max and min inserted_at ( **05 min 31 sec** )
19. Dump eventstore and readstore
20. Create 100_000 Accounts.ChangeUsername events  by running `Conduit.B.update_usernames_in_parallel(100_000)`
21. Get time from the create function, Author aggregates are in-memory currently, User aggregates are not in-memory ( **7852 sec or 2 hours 10 minutes 52 seconds** )
22. Get time for the User projection, diff between min/max updated_at ( **36 min 37 sec, the first update went into projection in 1 hour 34 minutes 15 seconds after create function started** )
23. Get time for the Author projection, diff between min/max updated_at ( **23 min 17 seconds, the first update went into projection in 3 hours 0 minutes 54 seconds (!!!)** )
24. Stop Elixir VM
25. Restore previous dump
26. Start the project
27. Create 100_000 Accounts.ChangeUsername events  by running `Conduit.B.update_usernames_in_parallel(100_000)`
28. Get time from the create function, Author aggregates are not in-memory, User aggregates are not in-memory ( **9439 sec or 2 hours 37 min 19 sec** )
29. Get time for the User projection, diff between min/max updated_at ( **42 minutes 55 seconds, the first update went into projection in 1 hour 54 minutes 17 seconds after create function started** )
30. Get time for the Author projection, diff between min/max updated_at ( **22 minutes 32 seconds, the first update went into projection in 3 hours 13 minutes 37 seconds after create function started** )
31. Stop Elixir VM
32. Enable Accounts.Projectors.Username in Accounts.Supervisor
33. Start the project and wait until all events are projected into the Username projection
34. Get time for projecting 105000 events (including UsernameUpdated) by checking the diff between max(updated_at) - min(inserted_at) - **1 minute 46 seconds**


# Conduit

Discover why functional languages, such as Elixir, are ideally suited to building applications following the command query responsibility segregation and event sourcing (CQRS/ES) pattern.

Conduit is a blogging platform, an exemplary Medium.com clone, built as a Phoenix web application.

This is the full source code to accompany the "[Building Conduit](https://leanpub.com/buildingconduit)" eBook.

This book is for anyone who has an interest in CQRS/ES and Elixir. It demonstrates step-by-step how to build an Elixir application implementing the CQRS/ES pattern using the [Commanded](https://github.com/slashdotdash/commanded) open source library.

---

MIT License

[![Build Status](https://travis-ci.com/slashdotdash/conduit.svg?branch=master)](https://travis-ci.com/slashdotdash/conduit)

---

## Getting started

Conduit is an Elixir application using Phoenix 1.4 and PostgreSQL for persistence.

### Prerequisites

You must install the following dependencies before starting:

- [Git](https://git-scm.com/).
- [Elixir](https://elixir-lang.org/install.html) (v1.6 or later).
- [PostgreSQL](https://www.postgresql.org/) database (v9.5 or later).

### Configuring Conduit

1. Clone the Git repo from GitHub:

    ```console
    $ git clone https://github.com/slashdotdash/conduit.git
    ```

2. Install mix dependencies:

    ```console
    $ cd conduit
    $ mix deps.get
    ```

3. Create the event store database:

    ```console
    $ mix do event_store.create, event_store.init
    ```

4. Create the read model store database:

    ```console
    $ mix do ecto.create, ecto.migrate
    ```

5. Run the Phoenix server:

    ```console
    $ mix phx.server
    ```

  This will start the web server on localhost, port 4000: [http://0.0.0.0:4000](http://0.0.0.0:4000)

This application *only* includes the API back-end, serving JSON requests.

You need to choose a front-end from those listed in the [RealWorld repo](https://github.com/gothinkster/realworld). Follow the installation instructions for the front-end you select. The most popular implementations are listed below.

- [React / Redux](https://github.com/gothinkster/react-redux-realworld-example-app)
- [Elm](https://github.com/rtfeldman/elm-spa-example)
- [Angular 4+](https://github.com/gothinkster/angular-realworld-example-app)
- [Angular 1.5+](https://github.com/gothinkster/angularjs-realworld-example-app)
- [React / MobX](https://github.com/gothinkster/react-mobx-realworld-example-app)

Any of these front-ends should integrate with the Conduit back-end due to their common API.

## Running the tests

```console
MIX_ENV=test mix event_store.create
MIX_ENV=test mix event_store.init
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```
## Need help?

Please [submit an issue](https://github.com/slashdotdash/conduit/issues) if you encounter a problem, or need support.
