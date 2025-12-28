# PmRails

PmRails is a toolset for testing or developing Ruby on Rails applications
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
2. **Create *and* develop** — installs gems into the project (`vendor/bundle/`) so you can continue developing with the PmRails toolset.

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
Gems are installed into the local `vendor/bundle/` directory, so the application can be developed without relying on the host Ruby environment.

> **Note:** Development mode currently expects **SQLite** as the local development and test database.

#### Create a New Rails Application Using pmrails-new-plus

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
* Installs gems into `vendor/bundle/`
* Adds `vendor/bundle/` to `.gitignore`

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


## Tips

### Reset the Gem Environment

If you encounter errors related to gems, resetting the local bundle directory often resolves the issue.
To do so, simply remove the `vendor/bundle/` directory:

```sh
rm -rf vendor/bundle/
```

After removing the directory, reinstall your gems by running:

```sh
pmbundle install
```
