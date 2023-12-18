# About

This is the source repository for [https://homosaurus.org](https://homosaurus.org).

Originally based on the [Oregon Digital Controlled Vocabulary Manager](https://github.com/OregonDigital/ControlledVocabularyManager) before being heavily modified.

# Local Setup

## Install Ruby and Rails

One needs a setup capable of running Ruby and Rails. One example is to use [RVM](https://rvm.io/). One should be able to
just accept their GPG keys and install RVM with:
```
> curl -sSL https://rvm.io/mpapis.asc | gpg --import -
> curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
> \curl -sSL https://get.rvm.io | bash -s stable
```

To install Ruby and use it as default, one would do:
```
> rvm install ruby-2.6.10 
> rvm --default use 2.6.10
```

Note that the last time I tried this, there was an issue with SSL from [this thread](https://github.com/rvm/rvm/issues/5209). To
get around that, I actually needed to do the following:
```
> sudo apt install build-essential
> mkdir ~/Downloads
> cd ~/Downloads
> wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz
> tar zxvf openssl-1.1.1g.tar.gz
> cd openssl-1.1.1g
> ./config --prefix=$HOME/.openssl/openssl-1.1.1g --openssldir=$HOME/.openssl/openssl-1.1.1g
> make
> make test # you might get a few tests failing but just ignore
> make install
> rm -rf ~/.openssl/openssl-1.1.1g/certs
> ln -s /etc/ssl/certs ~/.openssl/openssl-1.1.1g/certs
> cd ~
> rvm install ruby-2.6.10 --with-openssl-dir=$HOME/.openssl/openssl-1.1.1g
> rvm --default use 2.6.10
```

## Install MySQL (or equivalent like MariaDB)

Install a MySQL compatible server. For Ubuntu, this is:
```
> sudo apt-get install mysql-server
```

Also install libraries to be able to connect to that such as the following for Ubuntu:
```
> sudo apt-get install libmysqlclient-dev
``` 

It is recommended to secure that installation and have a homosaurus user with a db of the same name. Sample of commands for that:
```
> sudo mysql_secure_installation
> mysql -u root -p
>> CREATE USER 'homosaurus'@'%' IDENTIFIED BY 'new_password';
>> CREATE DATABASE homosaurus;
>> GRANT ALL PRIVILEGES ON homosaurus.* TO 'homosaurus'@'%';
>> ALTER DATABASE homosaurus CHARACTER SET utf8 COLLATE utf8_unicode_ci;
>> FLUSH PRIVILEGES;
```

## Install Blazegraph

This is used to cache the Library of Congress Linked Data and could be used in the future to cache other things. See
the quickstart guide from [https://github.com/blazegraph/database/wiki/Main_Page](https://github.com/blazegraph/database/wiki/Main_Page)
to run this locally. Once it is working, one can load a Library of Congress dataset using:

```
> wget https://lds-downloads.s3.amazonaws.com/lcsh.skos.nt.zip
> unzip lcsh.skos.nt.zip
> curl -H 'Content-Type: text/turtle' --upload-file /data/tools/blazegraph/lcsh.skos.nt -X POST "http://localhost:9999/blazegraph/sparql?context-uri=https://id.loc.gov/authorities/subjects"
``` 

## Rails Application

### Configuration

Modify the various "sample" files in the `config` directory (removing the sample). These should be:

#### data.yml.sample_mysql

Copy this to database.yml and edit it with your MySQL configuration.

#### homosaurus.yml.sample

Copy to homosaurus.yml. This shouldn't require modification unless one wants to test the captcha stuff.

#### contact_emails.yml.sample

Copy to contact_emails.yml.

#### solr.yml.sample

Copy to solr.yml.

#### blazegraph.yml.sample

Copy to blazegraph.yml.

### Installation

One needs a Javascript runtime, The easiest is nodejs that can be installed on Ubuntu using:
```
> sudo apt-get install nodejs
```

Next one needs to install all of the Ruby gems using: `bundle install` from the root directory. Once that has fully
succeeded, one can optionally export a copy of the database from the mysql on the server and bring that locally. 
The export and import commands are essentially:

Export:
```
mysqldump --lock-tables=false --set-gtid-purged=OFF --column-statistics=0 --no-tablespaces -P 3306 -h localhost -u homosaurus -p homosaurus > <dump_file>
```

Import:
```
mysql -u homosaurus -p homosaurus < <dump_file>
```

Once done, run `rake db:migrate` for rails to sync to the db state.

### Solr

Solr is the index used for the search functionality for the repository. For local development, once get copy the needed instance
files to the <project_root>/solr/binary folder with something like the following:
```
wget https://www.apache.org/dyn/closer.lua/lucene/solr/8.11.2/solr-8.11.2.tgz?action=download -P /<project_root>/solr/binary/solr-8.11.2.tgz
wget https://downloads.apache.org/lucene/solr/8.11.2/solr-8.11.2-src.tgz.sha512 -P /<project_root>/solr/binary/solr-8.11.2.tgz.sha512
```

The from the project root, once can  just use the command `solr_wrapper` to start a solr instance from the command prompt. 
If the index becomes corrupt (ie. from a restart where Solr wasn't shut down), then one can clear the Solr instance by 
deleting everything contained in the <project_root>/solr/instance/ directory.

### Running

The `rails c` command will bring up the console. One will need to run the following to populate the Solr index if using
the existing DB copy:
```
DSolr.reindex_all
```

The `rails s` command will start the application one should be able to reach at [http://localhost:3000](http://localhost:3000).