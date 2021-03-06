# puppet-storm [![Build Status](https://travis-ci.org/miguno/puppet-storm.png?branch=master)](https://travis-ci.org/miguno/puppet-storm)

[Wirbelsturm](https://github.com/miguno/wirbelsturm)-compatible [Puppet](http://puppetlabs.com/) module to deploy
[Storm](http://storm.incubator.apache.org/) 0.9+ clusters.

You can use this Puppet module to deploy Storm to physical and virtual machines, for instance via your existing
internal or cloud-based Puppet infrastructure and via a tool such as [Vagrant](http://www.vagrantup.com/) for local
and remote deployments.

---

Table of Contents

* <a href="#quickstart">Quick start</a>
* <a href="#features">Features</a>
* <a href="#requirements">Requirements and assumptions</a>
* <a href="#installation">Installation</a>
* <a href="#configuration">Configuration</a>
* <a href="#usage">Usage</a>
    * <a href="#configuration-examples">Configuration examples</a>
        * <a href="#hiera">Using Hiera</a>
        * <a href="#manifests">Using Puppet manifests</a>
    * <a href="#service-management">Service management</a>
    * <a href="#log-files">Log files</a>
* <a href="#development">Development</a>
* <a href="#todo">TODO</a>
* <a href="#changelog">Change log</a>
* <a href="#contributing">Contributing</a>
* <a href="#license">License</a>
* <a href="#references">References</a>

---

<a name="quickstart"></a>

# Quick start

See section [Usage](#usage) below.


<a name="features"></a>

# Features

* Supports Storm 0.9+, i.e. the latest stable release version.
* Only supports Netty as Storm's messaging backend, which is the default backend since Storm 0.9.  Support for the
  legacy ZeroMQ backend was deliberately removed from this module.
* Decouples code (Puppet manifests) from configuration data ([Hiera](http://docs.puppetlabs.com/hiera/1/)) through the
  use of Puppet parameterized classes, i.e. class parameters.  Hence you should use Hiera to control how Storm is
  deployed and to which machines.
* Supports RHEL OS family (e.g. RHEL 6, CentOS 6, Amazon Linux).
    * Code contributions to support additional OS families are welcome!
* Storm is run under process supervision via [supervisord](http://www.supervisord.org/) version 3.0+.


<a name="requirements"></a>

# Requirements and assumptions

* A Storm cluster requires a **ZooKeeper quorum** (1, 3, 5, or more ZooKeeper instances) for proper functioning.  Take a
  look at [puppet-zookeeper](https://github.com/miguno/puppet-zookeeper) to deploy such a ZooKeeper quorum for use with
  Storm.
* This module requires that the target machines to which you are deploying Storm have **yum repositories configured**
  for pulling the Storm package (i.e. RPM).
    * We provide [wirbelsturm-rpm-storm](https://github.com/miguno/wirbelsturm-rpm-storm) so that you can conveniently
      build such an RPM yourself.
    * Because we run Storm via supervisord through [puppet-supervisor](https://github.com/miguno/puppet-supervisor), the
      supervisord RPM must be available, too.  See [puppet-supervisor](https://github.com/miguno/puppet-supervisor)
      for details.
* This module requires that the target machines have a **Java JRE/JDK installed** (e.g. via a separate Puppet module
  such as [puppetlabs-java](https://github.com/puppetlabs/puppetlabs-java)).  You may also want to make sure that the
  Java package is installed _before_ Storm to prevent startup problems.
    * Because different teams may have different approaches to install "base" packages such as Java, this module does
      intentionally not puppet-require Java directly.
    * Note: Based on our own experience we strongly discourage the use of OpenJDK 6.  We run into many weird errors
      with it.  If you need Java 6 use Oracle/Sun Java 6.
* This module requires the following **additional Puppet modules**:

    * [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)
    * [puppet-supervisor](https://github.com/miguno/puppet-supervisor)

  It is recommended that you add these modules to your Puppet setup via
  [librarian-puppet](https://github.com/rodjek/librarian-puppet).  See the `Puppetfile` snippet in section
  _Installation_ below for a starting example.
* **When using Vagrant**: Depending on your Vagrant box (image) you may need to manually configure/disable firewall
  settings -- otherwise machines may not be able to talk to each other.  One option to manage firewall settings is via
  [puppetlabs-firewall](https://github.com/puppetlabs/puppetlabs-firewall).


<a name="installation"></a>

# Installation

It is recommended to use [librarian-puppet](https://github.com/rodjek/librarian-puppet) to add this module to your
Puppet setup.

Add the following lines to your `Puppetfile`:

```
# Add the stdlib dependency as hosted on public Puppet Forge.
#
# We intentionally do not include the stdlib dependency in our Modulefile to make it easier for users who decided to
# use internal copies of stdlib so that their deployments are not coupled to the availability of PuppetForge.  While
# there are tools such as puppet-library for hosting internal forges or for proxying to the public forge, not everyone
# is actually using those tools.
mod 'puppetlabs/stdlib'

# Add the puppet-storm module
mod 'storm',
  :git => 'https://github.com/miguno/puppet-storm.git'

# Add the puppet-supervisor module dependency
mod 'supervisor',
  :git => 'https://github.com/miguno/puppet-supervisor.git'
```

Then use librarian-puppet to install (or update) the Puppet modules.


<a name="configuration"></a>

# Configuration

* See [init.pp](manifests/init.pp) for the list of currently supported configuration parameters.  These should be
  self-explanatory.
* See [params.pp](manifests/params.pp) for the default values of those configuration parameters.

Of special note is the class parameter `$config_map`:  You can use this parameter to "inject" arbitrary Storm config
settings via Hiera/YAML into the Storm configuration file (default name: `storm.yaml`).  However you should not
re-define config settings via `$config_map` that already have explicit Puppet class parameters (such as `$nimbus_host`,
`$worker_childopts`).  See the examples below for more information on `$config_map` usage.


<a name="usage"></a>

# Usage

**IMPORTANT: Make sure you read and follow the [Requirements and assumptions](#requirements) section above.**
**Otherwise the examples below will of course not work.**


<a name="configuration-examples"></a>

## Configuration examples


<a name="hiera"></a>

### Using Hiera

A "full" single-node example that includes the deployment of [supervisord](http://www.supervisord.org/) via
[puppet-supervisor](https://github.com/miguno/puppet-supervisor) and
[ZooKeeper](http://zookeeper.apache.org/) via [puppet-zookeeper](https://github.com/miguno/puppet-zookeeper).
Here, both ZooKeeper and Storm (Logviewer, Nimbus, Supervisor, UI) are running on the same machine called
`stormsingle1`.  That's a nice setup for your local development laptop or CI server, for instance.

```yaml
---
classes:
  - storm::logviewer
  - storm::nimbus
  - storm::supervisor
  - storm::ui
  - supervisor
  - zookeeper::service

# Custom Storm settings
storm::zookeeper_servers:
  - 'stormsingle1'
storm::logviewer_childopts:  '-Xmx128m -Djava.net.preferIPv4Stack=true'
storm::nimbus_host: 'stormsingle1'
storm::nimbus_childopts:     '-Xmx256m -Djava.net.preferIPv4Stack=true'
storm::ui_childopts:         '-Xmx256m -Djava.net.preferIPv4Stack=true'
storm::supervisor_childopts: '-Xmx256m -Djava.net.preferIPv4Stack=true'
storm::worker_childopts:     '-Xmx256m -Djava.net.preferIPv4Stack=true'
storm::supervisor_slots_ports:
  - 6700
  - 6701
storm::storm_messaging_transport: "backtype.storm.messaging.netty.Context"
storm::config_map:
  nimbus.thrift.threads: 12
  storm.messaging.netty.server_worker_threads: 1
  storm.messaging.netty.client_worker_threads: 1
  storm.messaging.netty.buffer_size: 5242880
  storm.messaging.netty.max_retries: 100
  storm.messaging.netty.max_wait_ms: 1000
  storm.messaging.netty.min_wait_ms: 100
```

Of course you can (and normally will) use multiple Storm nodes.  Here, you will typically run Storm Nimbus and Storm UI
on the "master" machine, and a Storm Supervisor daemon on each of the "slave" machines in the Storm cluster.  Also, you
will typically have a dedicated ZooKeeper quorum.  Note that in small deployments you can alternatively also opt to use
only a single ZooKeeper instance, which is co-located with the Storm Nimbus/UI daemons on the same master machine.

Storm master node example, assuming the master node is called `nimbus1` and the ZooKeeper server is called `zookeeper1`:

```yaml
---
classes:
  - storm::nimbus
  - storm::ui
  - supervisor

## Custom Storm settings
storm::zookeeper_servers:
  - 'zookeeper1'
storm::nimbus_host: 'nimbus1'
storm::nimbus_childopts:     '-Xmx1024m -Djava.net.preferIPv4Stack=true'
storm::ui_childopts:         '-Xmx512m  -Djava.net.preferIPv4Stack=true'
# Add shell environment variables to the environment of the Nimbus process
storm::nimbus::service_environment: 'FOO="bar",HELLO="world"'
```

Storm slave node example:

```yaml
---
classes:
  - storm::logviewer
  - storm::supervisor
  - supervisor

## Custom Storm settings
storm::zookeeper_servers:
  - 'zookeeper1'
storm::logviewer_childopts:  '-Xmx128m -Djava.net.preferIPv4Stack=true'
storm::nimbus_host: 'nimbus1'
storm::supervisor_childopts: '-Xmx256m  -Djava.net.preferIPv4Stack=true'
storm::worker_childopts:     '-Xmx1024m -Djava.net.preferIPv4Stack=true'
storm::supervisor_slots_ports:
  - 6700
  - 6701
  - 6702
  - 6703
```


<a name="manifests"></a>

### Using Puppet manifests

_Note: It is recommended to use Hiera to control deployments instead of using this module in your Puppet manifests_
_directly._

TBD


<a name="service-management"></a>

## Service management

To manually start, stop, restart, or check the status of the Storm daemons, respectively:

    $ sudo supervisorctl [start|stop|restart|status] [storm-nimbus|storm-supervisor|storm-ui]

Example:

    $ sudo supervisorctl status
    storm-logviewer                  RUNNING    pid 7491, uptime 0:05:17
    storm-nimbus                     RUNNING    pid 7491, uptime 0:05:12
    storm-ui                         RUNNING    pid 7421, uptime 0:05:26
    storm-supervisor                 RUNNING    pid 7507, uptime 0:05:03


<a name="log-files"></a>

## Log files

_Note: The locations below may be different depending on the Storm RPM you are actually using._

* Storm log files: `/var/log/storm/*`
* Supervisord log files related to Storm processes:
    * `/var/log/supervisor/storm-nimbus/storm-nimbus.out`
    * `/var/log/supervisor/storm-nimbus/storm-nimbus.err`
    * `/var/log/supervisor/storm-supervisor/storm-supervisor.out`
    * `/var/log/supervisor/storm-supervisor/storm-supervisor.err`
    * `/var/log/supervisor/storm-ui/storm-ui.out`
    * `/var/log/supervisor/storm-ui/storm-ui.err`
* Supervisord main log file: `/var/log/supervisor/supervisord.log`


<a name="development"></a>

# Development

It is recommended run the `bootstrap` script after a fresh checkout:

    $ ./bootstrap

You have access to a bunch of rake commands to help you with module development and testing:

    $ bundle exec rake -T
    rake acceptance          # Run acceptance tests
    rake build               # Build puppet module package
    rake clean               # Clean a built module package
    rake coverage            # Generate code coverage information
    rake help                # Display the list of available rake tasks
    rake lint                # Check puppet manifests with puppet-lint / Run puppet-lint
    rake module:bump         # Bump module version to the next minor
    rake module:bump_commit  # Bump version and git commit
    rake module:clean        # Runs clean again
    rake module:push         # Push module to the Puppet Forge
    rake module:release      # Release the Puppet module, doing a clean, build, tag, push, bump_commit and git push
    rake module:tag          # Git tag with the current module version
    rake spec                # Run spec tests in a clean fixtures directory
    rake spec_clean          # Clean up the fixtures directory
    rake spec_prep           # Create the fixtures directory
    rake spec_standalone     # Run spec tests on an existing fixtures directory
    rake syntax              # Syntax check Puppet manifests and templates
    rake syntax:hiera        # Syntax check Hiera config files
    rake syntax:manifests    # Syntax check Puppet manifests
    rake syntax:templates    # Syntax check Puppet templates
    rake test                # Run syntax, lint, and spec tests

Of particular interest are:

* `rake test` -- run syntax, lint, and spec tests
* `rake syntax` -- to check you have valid Puppet and Ruby ERB syntax
* `rake lint` -- checks against the [Puppet Style Guide](http://docs.puppetlabs.com/guides/style_guide.html)
* `rake spec` -- run unit tests


<a name="todo"></a>

# TODO

* Restrict disk space used by logviewer log files.
* Enhance in-line documentation of Puppet manifests.
* Add more unit tests and specs.
* Add rollback/remove functionality to completely purge Storm related packages and configuration files from a machine.


<a name="changelog"></a>

## Change log

See [CHANGELOG](CHANGELOG.md).


<a name="contributing"></a>

## Contributing to puppet-storm

Code contributions, bug reports, feature requests etc. are all welcome.

If you are new to GitHub please read [Contributing to a project](https://help.github.com/articles/fork-a-repo) for how
to send patches and pull requests to puppet-storm.


<a name="license"></a>

## License

Copyright © 2014 Michael G. Noll

See [LICENSE](LICENSE) for licensing information.


<a name="references"></a>

# References

Puppet modules similar to this module:

* [wikimedia/puppet-kafka](https://github.com/wikimedia/puppet-kafka) -- focuses on Debian as the target OS, and
  apparently also supports Kafka mirroring and jmxtrans monitoring (the latter for sending JVM and Kafka broker metrics
  to tools such as Ganglia or Graphite)

The test setup of this module was derived from:

* [puppet-module-skeleton](https://github.com/garethr/puppet-module-skeleton)
