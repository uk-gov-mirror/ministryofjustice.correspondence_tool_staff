# Correspondence Tools - Staff
[![Build Status](https://semaphoreci.com/api/v1/correspondence-tool/correspondence_tool_staff-4/branches/master/badge.svg)](https://semaphoreci.com/correspondence-tool/correspondence_tool_staff-4)
[![Code Climate](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/gpa.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)
[![Test Coverage](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/coverage.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/coverage)
[![Issue Count](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/issue_count.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)


A simple application to allow internal staff users to answer correspondence.

## Development

### Working on the Code

Work should be based off of, and PRed to, the master branch. We use the GitHub
PR approval process so once your PR is ready you'll need to have one person
approve it, and the CI tests passing, before it can be merged. Feel free to use
the issue tags on your PR to indicate if it is a WIP or if it is ready for
reviewing.


### Basic Setup

#### Cloning This Repository

Clone this repository then `cd` into the new directory

```
$ git clone git@github.com:ministryofjustice/correspondence_tool_staff.git
$ cd correspondence_tool_staff
```

### Installing the app for development

#### Installing Dependencies

If you want to run the app natively on your mac, follow these instructions to install dependencies.

##### Installing Postgres 12.5.x

We use version 12.5.x of PostgreSQL to match what we have in the deployed
environments. Also, because the `structure.sql` file generated by PostgreSQL
can change with every different version postgres, all developers on the project
should use the same version to prevent minor changes to the structure file on each commit.

There are two options for installing postgres:

* **The Postgres OS X application**
	* Download the Postgres application from the App Store
	* Start the app, click the plus sign bottom left, and add a new server, specifying 12.5.
* **The Homebrew postgres 12.5 package**
	Install the specific 12.5 version with homebrew

```
$ brew install postgresql@12
```

Having done this, make sure all the post-install variables have been put in
`.bash_profile` or similar e.g.

```
export PKG_CONFIG_PATH="/usr/local/opt/postgresql@12/lib/pkgconfig"
export CPPFLAGS="-I/usr/local/opt/postgresql@12/include"
export LDFLAGS="-L/usr/local/opt/postgresql@12/lib"
export PATH=$PATH:/usr/local/opt/postgresql@12/bin
```

The PKG_CONFIG_PATH and PATH are useful to help install the PG gem

##### Latest Version of Ruby

If you don't have `rbenv` already installed, install it as follows:
```
brew install rbenv
rbenv init
```

Use `rbenv` to install the latest version of ruby as defined in `.ruby-version` (make sure you are in the repo path):

```
$ rbenv install
$ rbenv init
$ rbenv rehash
```
Follow the instructions printed out from the `rbenv init` command and update your `~/.bash_profile` file accordingly, then start a new terminal and navigate to the repo directory.

```
$ gem install bundler -v 2.2.11
```

##### Installing Latest XCode Stand-Alone Command-Line Tools

May be necessary to ensure that libraries are available for gems, for example
Nokogiri can have problems with `libiconv` and `libxml`.

```
$ xcode-select --install
```

<summary>Issues installing PostgreSQL (pg) gem</summary>
<details>
When running `bundle install` on MacOS `gem pg` may fail to build and install.

(These issues may not occur if following the instructions above about setting the PKG_CONFIG_PATH)

Error with missing libpq-fe.h

Assuming the installation steps have been followed, execute in Terminal:

export CONFIGURE_ARGS="with-pg-include=/usr/local/opt/postgresql@12/include";
gem install pg -v '1.1.4' --source 'https://rubygems.org/';

And ensure you add the following to `.bash_profile` or similar to prevent TCP connection errors:

export PGHOST=localhost

</details>

##### Installing Redis

Redis is needed to run the 'db:reseed' task. Redis is used as the adapted for
delayed jobs in the system.

```
brew install redis
```
</details>

##### Testing

This project can produce code coverage data (w/o JS or views) using the `simplecov` gem
set COVERAGE=1 (or any value) to generate a coverage report.
Parallel tests are supposed to be supported - however the coverage output from simplecov is a little
strange (the total lines in the project are different for each coverage run)

This project includes the `parallel_tests` gem which enables multiple CPUs to be used during testing
in order to speed up execution. Otherwise running the tests takes an unacceptably long amount of time.

The default parallelism is 8 (override by setting PARALLEL_TEST_PROCESSORS) which seems to be about
right for a typical Macbook Pro (10,1 single processor with 4 cores)

##### To set up parallel testing

Create the required number of extra test databases:
```
rails parallel:create
```
Load the schema into all of the extra test databases:
```
rails parallel:load_structure
```
###### To run all the tests in parallel
```
rails parallel:spec
```
###### To run only feature tests in parallel
```
rails parallel:spec:features
```
###### To run only the non-feature tests in parallel
```
rails parallel:spec:non_features
```

###### Browser testing

We use [headless chrome](https://developers.google.com/web/updates/2017/04/headless-chrome)
for Capybara tests, which require JavaScript. You will need to install Chrome >= 59.
Where we don't require JavaScript to test a feature we use Capybara's default driver
[RackTest](https://github.com/teamcapybara/capybara#racktest) which is ruby based
and much faster as it does not require a server to be started.

**Debugging:**

To debug a spec that requires JavaScript, you need to set a environment variable called CHROME_DEBUG.
It can be set to any value you like.

Examples:
```
$ CHROME_DEBUG=1 bundle exec rspec
```
When you have set `CHROME_DEBUG`, you should notice chrome start up and appear on your
taskbar/Docker. You can now click on chrome and watch it run through your tests.
If you have a `binding.pry`  in your tests the browser will stop at that point.

#### Database Setup

Run these rake tasks to prepare the database for local development.
```
$ rails db:create
$ rails db:reseed
```

The `db:reseed` rake task will:
 - clear the database  by dropping all the tables and enum types
 - load the structure.sql
 - run all the data migrations

This will have the effect of setting up a standard set of teams, users, reports, correspondence types, etc.  The `db:reseed` can be used at any point you want reset the database without
having to close down all clients using the database.

##### Creating individual test correspondence items

Individual correspondence items can be quickly created by logging in as David Attenborough, and using the admin tab to create any kind of case in any state.

##### Creating bulk test correspondence items

To create 200 cases in various states with various responders for search testing, you can use the following rake task:
```
rake seed:search:data
```
It appears that redis needs to be running to attempt this task - but it doesn't currently work for unknown reasons.

### Additional Setup

#### Libreoffice

Libreoffice is used to convert documents to PDF's so that they can be viewed in a browser.
In production environments, the installation of libreoffice is taken care of during the build
of the docker container (see the Dockerfile).

In localhost dev testing environments, libreoffice needs to be installed using homebrew, and then
the following shell script needs to created with the name ```/usr/local/bin/soffice```:

```
cd /Applications/LibreOffice.app/Contents/MacOS && ./soffice $1 $2 $3 $4 $5 $6
```

The above script is needed by the libreconv gem to do the conversion.

#### BrowserSync Setup

[BrowserSync](https://www.browsersync.io/) is setup and configured for local development
using the [BrowserSync Rails gem](https://github.com/brunoskonrad/browser-sync-rails).
BrowserSync helps us test across different browsers and devices and sync the
various actions that take place.

##### Dependencies

Node.js:
Install using `brew install node` and then check its installed using `node -v` and `npm -v`

- [Team Treehouse](http://blog.teamtreehouse.com/install-node-js-npm-mac)
- [Dy Classroom](https://www.dyclassroom.com/howto-mac/how-to-install-nodejs-and-npm-on-mac-using-homebrew)

##### Installing and running:

Bundle install as normal then
After bundle install:

```bash
bundle exec rails generate browser_sync_rails:install
```

This will use Node.js npm (Node Package Manager(i.e similar to Bundle or Pythons PIP))
to install BrowserSync and this command is only required once. If you run into
problems with your setup visit the [Gems README](https://github.com/brunoskonrad/browser-sync-rails#problems).

To run BrowserSync start your rails server as normal then in a separate terminal window
run the following rake task:

```bash
bundle exec rails browser_sync:start
```

You should see the following output:
```
browser-sync start --proxy localhost:3000 --files 'app/assets, app/views'
[Browsersync] Proxying: http://localhost:3000
[Browsersync] Access URLs:
 ------------------------------------
       Local: http://localhost:3001
    External: http://xxx.xxx.xxx.x:3001
 ------------------------------------
          UI: http://localhost:3002
 UI External: http://xxx.xxx.xxx.x:3002
 ------------------------------------
[Browsersync] Watching files...
```
Open any number of browsers and use either the local or external address and your
browser windows should be sync. If you make any changes to assets or views then all
the browsers should automatically update and sync.

The UI URL are there if you would like to tweak the BrowserSync server and configure it further

#### Emails

Emails are sent using
the [GOVUK Notify service](https://www.notifications.service.gov.uk).
Configuration relies on an API key which is not stored with the project, as even
the test API key can be used to access account information. To do local testing
you need to have an account that is attached to the "Track a query" service, and
a "Team and whitelist" API key generated from the GOVUK Notify service website.
See the instructions in the `.env.example` file for how to setup the correct
environment variable to override the `govuk_notify_api_key` setting.

The urls generated in the mail use the `cts_email_host` and `cts_mail_port`
configuration variables from the `settings.yml`. These can be overridden by
setting the appropriate environment variables, e.g.

```
$ export SETTINGS__CTS_EMAIL_HOST=localhost
$ export SETTINGS__CTS_EMAIL_PORT=5000
```

#### Uploads

Responses and other case attachments are uploaded directly to S3 before being
submitted to the application to be added to the case. Each deployed environment
has the permissions is needs to access the uploads bucket for that environment.

In local development, uploads are placed in https://<cloud-platform-generated-s3-bucket-address>/

You'll need to provide access credentials to the aws-sdk gems to access
it, there are two ways of doing this:

#### Using credentials attached to your IAM account

In order to perform certain actions, you need to have valid S3 credentials active
You can configure the aws-sdk with your access and secret key by placing them in
 the `[default]` section in `.aws/credentials`:

Retrieve details from the secret created in Kubernetes in the  [s3.tf terraform resource](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/live-1.cloud-platform.service.justice.gov.uk/track-a-query-development/resources/s3.tf#L74)


`kubectl -n track-a-query-production get secret track-a-query-ecr-credentials-output -o yaml`

Decode the base64 encoded values for access_key_id and secret_access_key from the output returned e.g.

`$ echo QUtHQTI3SEpTERJV1RBTFc= | base64 --decode; echo`

Place them in `~/.aws/credentals` as the default block:

```
[default]
aws_access_key_id = AKIA27HHJDDH3GHI
aws_secret_access_key = lSlkajsd9asdlaksd73hLKSFAk

```

#### Dumping the database

We have functionality to create an anonymised copy of the production or staging database. This feature is to be used as a very last resort. If the copy of the database is needed for debugging please consider the following options first:
- seeing if the issue is covered in the feature tests
- trying to track the issue through Kibana
- recreating the issue locally

If the options above do not solve the issue you by create an anonymised dump of the database by running

```
rake db:dump:prod[host]
```

there are also options to create an anonymised version of the local database

```
rake db:dump:local[filename,anon]
```

or a standard copy

```
rake db:dump:local[filename,clear]
```

For more help with the data dump tasks run:

```
rake db:dump:help
```


### Papertrail

The papertrail gem is used as an auditing tool, keeping the old copies of records every time they are
changed.  There are a couple of complexities in using this tool which are described below:

#### JSONB fields on the database
The default serializer does not de-serialize the properties column correctly because internally it is
held as JSON, and papertrail serializes the object in YAML.  The custom serializer ```CtsPapertrailSerializer```
takes care of this and reconstitutes the JSON fields correctly.  See ```/spec/lib/papertrail_spec.rb``` for
examples of how to reify a previous version, or get a hash of field values for the previous version.

### Continuous Integration

Continuous integration is carried out by SemaphoreCI.

### Data Migrations

The app uses the `rails-data-migrations` gem https://github.com/OffgridElectric/rails-data-migrations

Data migrations work like regular migrations but for data; they're found in `db/data_migrations`.

To create a data migration you need to run:

`rails generate data_migration migration_name`

and this will create a `migration_name.rb` file in `db/data_migrations` folder with the following content:

```
class MigrationName < DataMigration
  def up
    # put your code here
  end
end
```

Finally, at release time, you need to run:

`rake data:migrate`

This will run all pending data migrations and store migration history in data_migrations table.

### Letter templates and synchronising data

The app has templated correspondence for generating case-related letters for the Offender SAR case type.

The template body for each letter is maintained in the `letter_templates` table in the database, and populated from information in the /db/seeders/letter_template_seeder.rb script.

Whenever any changes to the letter templates are required DO NOT EDIT THE DATABASE, but amend the seeder and then on each environment, run `rails db:seed:dev:letter_templates` to delete and re-populate the table.

This is required whenever any new template is added; should someone have edited the versions in the database directly, those changes will be overwritten the next time the seeder is run.

### Smoke Tests

The smoke test runs through the process of signing into the service using a dedicated user account setup as Disclosure BMT team member.
It checks that sign in was successful and then randomly views one case in the case list view.

To run the smoke test, set the following environment variables:

```
SETTINGS__SMOKE_TESTS__USERNAME    # the email address to use for smoke tests
SETTINGS__SMOKE_TESTS__PASSWORD    # The password for the smoketest email account
```

and then run

```
bundle exec rails smoke
```
### Site prism page manifest file

The tests use the Site Prism gem to manage page objects which behave as an abstract description of the pages in the application; they're used in feature tests for finding elements, describing the URL path for a given page and for defining useful methods e.g. for completing particular form fields on the page in question.

If you add new Site Prism page objects, it's easy to follow the existing structure - however, there is one gotcha which is that in order to refer to them in your tests, you also need to add the new objects to a manifest file here so that it maps an instantiated object to the new Page object class you've defined.

See `spec/site_prism/page_objects/pages/application.rb`

### Localisation keys checking

As part of the test suite, we check to see if any `tr` keys are missing from the localised YAML files

There is a command line tool provided to check for these manually as well - `i18n-tasks missing` - you can see the output from it below.

```
$ i18n-tasks missing
Missing translations (1) | i18n-tasks v0.9.29
+--------+------------------------------------+--------------------------------------------------+
| Locale | Key                                | Value in other locales or source                 |
+--------+------------------------------------+--------------------------------------------------+
|  all   | offender_sars.case_details.heading | app/views/offender_sars/case_details.html.slim:5 |
+--------+------------------------------------+--------------------------------------------------+

...fixing happens...

$ i18n-tasks missing
✓ Good job! No translations are missing.
$
```
There's also a similar task called `i18n-tasks unused`

```
$ i18n-tasks unused
Unused keys (1) | i18n-tasks v0.9.29
+--------+-----------------------+---------------+
| Locale | Key                   | Value         |
+--------+-----------------------+---------------+
|   en   | steps.new.sub_heading | Create a case |
+--------+-----------------------+---------------+
$ i18n-tasks unused
✓ Well done! Every translation is in use.
$
```

### Deploying

#### Dockerisation

Docker images are built from a single `Dockerfile` which uses build arguments to
control aspects of the build. The available build arguments are:

- _*development_mode*_ enable by setting to a non-nil value/empty string to
  install gems form the `test` and `development` groups in the `Gemfile`. Used
  when building with `docker-compose` to build development versions of the
  images for local development.
- _*additional_packages*_ set to the list of additional packages to install with
  `apt-get`. Used by the build system to add packages to the `uploads` container:

  ```
      clamav clamav-daemon clamav-freshclam libreoffice
  ```

  These are required to scan the uploaded files for viruses (clamav & Co.) and
  to generate a PDF preview (libreoffice).


  ```
      nodejs
  ```

  Required to run Puma with ExecJS


  ```
      zip
  ```

  Required to run closed case reports

#### Generating Documentation
 
You can generate documentation for the project with:

```
bundle exec yardoc
```

If you need to you can edit settings for Yard in `Rakefile`. The documentation
is generated in the `doc` folder, to view it on OSX run:

```
open doc/index.html
```

#### Guide to our deploy process
For our deploy process please see the our [confluence page](https://dsdmoj.atlassian.net/wiki/spaces/CD/pages/164660145/Manual+-+Development+and+Release+Process)


## Keeping secrets and sensitive information secure

### Uninstall overcommit

If you have installed overcommit in the past, then you need to uninstall it in order to get git-secrets' hooks work properly, the steps are:-

Uninstall the gem

    $ gem uninstall overcommit

Remove the rules from .git/config file under [overcommit] section
Remove the following hooks from ./git/hooks (Do check them before deleting them)
```
commit-msg		
post-commit		
post-rewrite		
pre-push		
prepare-commit-msg
overcommit-hook		
post-checkout		
post-merge		
pre-commit		
pre-rebase
```

### git-secrets

To prevent the commitment of secrets and credentials into git repositories we use awslabs / git-secrets (https://github.com/awslabs/git-secrets)

For MacOS, git-secrets can be install via Homebrew.  From the terminal run the following:

    $ brew install git-secrets

Then install the git hooks:

    $ cd /path/to/my/repo
    $ git secrets --install
    $ git secrets --register-aws

A 'canary' string has been added to the first line of the secrets.yaml files on all environments.  Git Secrets has to be set to look for this string with:

    $ git secrets --add --literal '#WARNING_Secrets_Are_Not_Encrypted!'

**Please note** please make sure use --literal with exact string, forget to use this flag and change any bit of the string will cause the checking for those files skippped 

Finally checking the installation result:-
First, check the hooks, open your local repository .git/hooks/, a few new hooks should have installed: pre-commit, commit-msg, prepare-commit-msg, each file should look something like this:

    #!/usr/bin/env bash
    git secrets --pre_commit_hook -- "$@"

Second, check the .git/config, a new section called [secrets] should have been added by end of this file, you should be able to see the rules from aws and the one for 'canary' string.

**How it works**

When committing a branch change git-secrets scans the whole repository for a specific set of strings.  In this case, the 'canary' string (described above) has been placed in all the secrets files. So, if the encrypted secrets files are unlocked, you will be warned before pushing the branch.


### git-crypt

The tool is used for encryping sensitive information such as secrets or keys information
e.g. 
Sensitive information required to deploy the application into Cloud Platform
are stored in the appropriate environment settings folders found in

```
config/kubernetes/<environment>/secrets.yaml
```
For MacOS brew users: `brew install git-crypt`

For other installation guides: https://github.com/AGWA/git-crypt

To decrypt secrets, you must require authorization from your line manager.

**Are about to add new secret files?**
Please remember:
Add the 'canary' string into the new secret file. 
Make sure this file is within the scope defined in the .gitattributes, if not, you need to add it in 

If in doubt about handling any secure credentials please do not hesitate to `#ask-cloud-platform`
or `#security` in MOJ Slack.

# Case Journey
1. **unassigned**
   A new case entered by a DACU user is created in this state.  It is in this state very
   briefly before it the user assigns it to a team on the next screen.

1. **awaiting_responder**
   The new case has been assigned to a business unit for response.

1. **drafting**
   A kilo in the responding business unit has accepted the case.

1. **pending_dacu_clearance**
   For cases that have an approver assignment with DACU Disclosure, as soon as a
   response file is uploaded, the case will transition to pending_dacu disclosure.
   The DACU disclosure team can either clear the case, in which case it goes forward to
   awaiting dispatch, or request changes, in which case it goes back to drafting.

1. **awaiting_dispatch**
   The Kilo has uploaded at least one response document.

1. **responded**
   The kilo has marked the response as sent.

1. **closed**
   The kilo has marked the case as closed.

# How to upgrade Ruby 2.5.x to Ruby 2.7.x on local environment 

1. Checkout the branch with ruby version defined as 2.7.2 in .ruby-version

2. Install Ruby 2.7.2

```
$ rbenv install
```
it should pick up the version defined in .ruby-version 

If you get error somehow telling you not being able to find available stable relesae 2.7.2, you could try the following commands

```
$ brew unlink ruby-build
$ brew install --HEAD ruby-build 
```

then run following command to check whether you can see 2.7.2 in the list
```
$ rbenv install --list-all
```
once you confirm, you can re-run `rbenv install` comand to continue the process.

3. Update the gem system 
```
$ gem update --system
```

4. Install bundle 2.2.11 and install those gems 
```
$ gem install bundler -v 2.2.11
$ bundler install
```

5. run `rails s` check the app