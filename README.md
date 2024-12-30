# PmRails

PmRails is a toolset for testing or developing Ruby on Rails applications
without installing Rails or its dependencies into your local environment.
It leverages [Podman](https://docs.podman.io/en/latest/)
to create an isolated, containerized environment for your Rails projects.

## Why Use PmRails?

- **Clean Local Environment**: No need to install Rails or dependencies locally.
- **Quick Setup**: Start developing immediately if Podman is installed.
- **Consistent and Reproducible Environments**: Isolated containers prevent dependency conflicts, making it ideal for team collaboration.
- **Experiment Freely**: Safely test different Rails versions or configurations.

## Features

PmRails provides the following commands:

- **`pmrails`**: Runs Rails commands as a wrapper for `bin/rails`.
  **Usage**: `pmrails COMMAND [OPTIONS]`

- **`pmrails-new`**: Creates a new Rails application as a wrapper for `bin/rails new`.
  **Usage**: `pmrails-new RAILS_VERSION APP_PATH [OPTIONS]`

- **`pmexec`**: Executes arbitrary commands within the containerized environment.
  **Usage**: `pmexec COMMAND [OPTIONS]`

- **`pmbundle`**: Manages gems as a wrapper for `bundle`.
  **Usage**: `pmbundle [BUNDLE_ARGS]`
  Gems are installed into the `vendor/bundle/` directory, which is used by `pmrails`.

To reset the gem environment, simply delete the `vendor/bundle/` directory:

```sh
rm -rf vendor/bundle/
```

## Installation

### Prerequisites: Install Podman

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

### Creating a New Rails Application

Navigate to a temporary directory. For example:

```sh
mkdir -p ~/tmp
cd ~/tmp
```

Create a new Rails app using the desired Rails version:

```sh
pmrails-new 8.0.1 sample_app --skip-bundle
```

Move to the application directory:

```sh
cd sample_app
```

Run Bundler to install Gems:

```sh
pmbundle install
```

If using Git for your app, add `/vendor/bundle/` to `.gitignore`. For example:

```sh
echo /vendor/bundle/ >> .gitignore
```

### Running Rails Commands

To run Rails commands, use pmrails. For example, to start the server:

```sh
pmrails server -b 0.0.0.0
```

Then, open your web browser and navigate to `http://localhost:3000/`.

More Examples:

```sh
# Run database migrations
pmrails db:migrate

# Execute tests
pmrails test

# Open the Rails console
pmrails console

# Run the Rails setup script
pmexec bin/setup
```
