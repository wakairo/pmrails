# PmRails

PmRails is a toolset for testing and developing Ruby on Rails applications
without installing Rails or its dependencies on your local machine.
It leverages [Podman](https://docs.podman.io/en/latest/)
to create an isolated, containerized environment for your Rails projects.


## Why Use PmRails?

- **Clean Local Environment**: No need to install Rails or dependencies locally.
- **Quick Setup**: Start developing immediately once Podman is installed.
- **Consistent and Reproducible Environments**: Isolated containers prevent dependency conflicts, making it ideal for team collaboration.
- **Experiment Freely**: Safely test different Rails versions or configurations.


## Features

PmRails provides the following commands:

- **`pmrails`**: Runs Rails commands as a wrapper around `bin/rails`.\
  **Usage**: `pmrails COMMAND [OPTIONS]`

- **`pmrails-new`**: Creates a new Rails application as a wrapper around `rails new`.\
  **Usage**: `pmrails-new RAILS_VERSION APP_PATH [OPTIONS]`

- **`pmrails-new-plus`**: Performs the typical setup tasks for developing a new Rails application with PmRails in a single step.\
  **Usage**: `pmrails-new-plus RAILS_VERSION APP_PATH [OPTIONS]`

- **`pmrailsenvexec`**: Executes arbitrary commands within the containerized environment.\
  **Usage**: `pmrailsenvexec COMMAND [OPTIONS]`

- **`pmbundle`**: Manages gems as a wrapper around `bundle`.\
  **Usage**: `pmbundle [BUNDLE_ARGS]`


## Installation

### Prerequisites

You must have Podman installed.
Follow the [Podman Installation Instructions](https://podman.io/docs/installation) for your operating system.

### Install PmRails

Download PmRails to your preferred location. For example:

```sh
mkdir -p ~/.var
cd ~/.var
git clone https://github.com/wakairo/pmrails.git
```

Add the `bin` directory to your system's PATH environment variable. For example, using bash:

```sh
echo 'export PATH="$HOME/.var/pmrails/bin/:$PATH"' >> ~/.bashrc
exec $SHELL -l
```


## Usage

PmRails has two primary modes:

1. **Create a new Rails application only** — runs `rails new` inside a container.
2. **Create *and* develop** — installs gems into the project (`.pmrails/var/bundle/`) to enable development with the PmRails toolset.

### 1. Create a New Rails Application Only

Use this mode if you only want to generate the application files and intend to run the application in another environment.
`pmrails-new` behaves the same as `rails new`.

Navigate to a temporary directory. For example:

```sh
mkdir -p ~/tmp
cd ~/tmp
```

Create a new Rails application, specifying the Rails version and any `rails new` options you need. For example:

```sh
pmrails-new 8.1 new_app --database=postgresql
```

### 2. Create and Develop a Rails Application

Use this mode when you plan to keep developing the application with PmRails.
Gems are installed into the local `.pmrails/var/bundle/` directory, so the application can be developed without relying on the host Ruby environment.

> **Note:** This section shows development with **SQLite**. However, you can use external databases (PostgreSQL, MySQL, etc.) by configuring your application — see **Using an External Database** below for examples.

#### Create a New Rails Application Using `pmrails-new-plus`

Navigate to a temporary directory. For example:

```sh
mkdir -p ~/tmp
cd ~/tmp
```

Create a new Rails application with `pmrails-new-plus`:

```sh
pmrails-new-plus 8.1 sample_app
```

When using this command, any `rails new` options can be specified after the application name.

`pmrails-new-plus` automatically performs the following tasks:

* Creates a new Rails application
* Installs gems into `.pmrails/var/bundle/`
* Adds `.pmrails/var/` to `.gitignore`

#### Run Rails Commands

Navigate to the application directory:

```sh
cd sample_app
```

Use `pmrails` to run Rails commands. For example, to start the server:

```sh
pmrails server -b 0.0.0.0
```

Then, open your web browser and navigate to `http://localhost:3000/`.

#### More Examples

```sh
# Run Bundler to install gems
pmbundle install

# Run database migrations
pmrails db:migrate

# Execute tests
pmrails test

# Open the Rails console
pmrails console

# Run the Rails setup script
pmrailsenvexec bin/setup
```


## `.pmrails` — Local Directories and Environment Variables

PmRails keeps all project-specific runtime files (gems, caches, configs, state)
inside a project-local directory named `.pmrails/var/`.
It sets environment variables to direct the containerized process to use these paths.
This design keeps your host user account clean and ensures the project is self-contained.

The following table shows how environment variables are mapped to project-local directories:

| Environment Variable (Container) |  Project Path (Repo Root) | Purpose                                            |
| -------------------------------- | ------------------------: | -------------------------------------------------- |
| `HOME`                           |       `.pmrails/var/home` | Process HOME — where tools write dotfiles          |
| `XDG_CACHE_HOME`                 |      `.pmrails/var/cache` | Tool caches                                        |
| `XDG_CONFIG_HOME`                |     `.pmrails/var/config` | Per-user configuration files                       |
| `XDG_DATA_HOME`                  |      `.pmrails/var/share` | Optional data files used by some tools             |
| `XDG_STATE_HOME`                 |      `.pmrails/var/state` | Optional state files used by some tools            |
| `BUNDLE_PATH`                    |     `.pmrails/var/bundle` | Bundler gem installation path (project-local gems) |

### Benefits of this Design

* **Cleanliness:** Keeps the host user’s `~/.gem`, `~/.bundle`, and other personal files untouched.
* **Isolation:** Makes project state local and easy to reset.

### Managing the `.pmrails` Directory

-   **Git:** Do not commit `.pmrails/var/` to source control. `pmrails-new-plus` adds it to `.gitignore` automatically.
-   **Reset:** `.pmrails/var/` is safe to remove. If you encounter issues, run `rm -rf .pmrails/var` and then `pmbundle install` to reset the environment.
-   **Security:** In multi-user environments, ensure `.pmrails/` is readable only by your user (e.g., `chmod -R go-rwx .pmrails`), as it may contain credentials or cached data.


## Ruby Version Resolution

PmRails determines which Ruby version to use based on the presence and content
of a `.ruby-version` file in the current directory.

### Commands That Read `.ruby-version`

The following commands read `.ruby-version` to determine the Ruby version:

- `pmbundle`
- `pmrails`
- `pmrailsenvexec`

### Behavior When `.ruby-version` Is Present or Absent

- **When `.ruby-version` exists:**
  PmRails extracts a Ruby version from the first line of the file and uses the corresponding container image.

- **When `.ruby-version` does not exist:**
  PmRails defaults to using `ruby:latest`.

### Accepted `.ruby-version` Format

PmRails looks for a `MAJOR.MINOR.PATCH` pattern
on the **first line** of `.ruby-version`
and uses the first match found.

Accepted examples:

- `3.2.2`
- `ruby-4.0.1` (the numeric `4.0.1` part is extracted)

If no `MAJOR.MINOR.PATCH` sequence is found on the first line,
the command exits with an error.
This design choice ensures unambiguous and reproducible container image selection.

### Relationship to Container Images

The value read from `.ruby-version` is used directly as a container image tag:

> `ruby:<major.minor.patch>`

For example:

> `.ruby-version`: `3.2.2` -> `ruby:3.2.2`

PmRails does not perform version normalization or compatibility checks.

### Changing Ruby Versions

Changing the Ruby version in `.ruby-version` effectively switches the container
image used by PmRails.

When doing so, previously generated local data (such as installed gems under
`.pmrails/var/`) may no longer be compatible. If you encounter issues after changing
the Ruby version, removing the `.pmrails/var/` directory and reinstalling gems
is usually sufficient.


## Using an External Database

PmRails can connect to a database running on the host or to a separately run database container.
One convenient method to have Rails (running inside a PmRails container) reach a host-bound database is to use `host.containers.internal`.

Though the following example is for PostgreSQL, the same approach works for other databases: start a database container on the host with the `-p` option to publish its port, and set `host: host.containers.internal` in `database.yml` with the appropriate adapter and credentials.

### Start a PostgreSQL Server (example)

Run PostgreSQL as a host-bound container:

```sh
podman run -d --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=your_password postgres:latest
```

### Example `config/database.yml`

Point your Rails application to the host database by using `host.containers.internal`:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: sample_app_development
  username: postgres
  password: your_password
  host: host.containers.internal

test:
  <<: *default
  database: sample_app_test
  username: postgres
  password: your_password
  host: host.containers.internal
```

After editing the config, run your usual PmRails commands (for example, `pmrails db:create` and `pmrails server -b 0.0.0.0`). The Rails process inside the PmRails container should then connect to the PostgreSQL server running in another container on the host.

### Reference: Stop / Start / Remove the PostgreSQL Container

Useful commands for lifecycle management of the host PostgreSQL container:

```sh
# stop the postgres container
podman stop postgres

# start (resume) the postgres container
podman start postgres

# remove the postgres container (before removing, stop the container)
podman rm postgres
```


## Limitations

PmRails is designed as a lightweight, predictable wrapper around Podman.
To maintain simplicity and transparency, it makes several assumptions and trade-offs.

### Fixed Port Forwarding

The `pmrails` and `pmrailsenvexec` commands forward port **3000** from the container to the host by default.

* This aligns with the default Rails development server port.
* If port 3000 is already in use on the host, these commands will fail.
* Custom port mappings are not supported at this time.

### New Apps Use `ruby:latest`

The `pmrails-new` and `pmrails-new-plus` commands always use the `ruby:latest` container image.

* The Ruby version referenced by `latest` changes over time.
* The environment used to generate a new Rails application may differ from the runtime environment specified later in `.ruby-version`.

### SELinux Considerations

On systems with SELinux enabled, mounted host directories may not be writable from inside the container.

* PmRails does **not** automatically apply `:z` or `:Z` mount options.
* If access is denied, users are expected to adjust SELinux contexts manually (for example, using `chcon`).
* This behavior is intentional to avoid implicitly weakening SELinux security policies.
