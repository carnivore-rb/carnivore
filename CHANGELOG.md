# v0.3.14
* Call out errors caught that were not handled
* Add tight constraint on celluloid due to major changes in 0.17

# v0.3.12
* Remove config loader to prevent early loading

# v0.3.10
* Do not reset comms for local loop back to prevent looping aliases
* Allow content to be provided and auto nest

# v0.3.8
* Re-add config file for libraries doing direct loading
* Ensure source teardown does not hang

# v0.3.6
* Add `Carnivore::Source.clear!` helper
* Integrate memoization helpers
* Fix up config specs to proper load in config

# v0.3.4
* Remove loading of unused CLI library
* Only terminate callback supervisor if alive
* Set logging level to debug if env var is set

# v0.3.2
* Update auto configuration behavior
* Return configuration instance when running configure

# v0.3.0
* Remove custom rolled configuration
* Auto define configuration when not set prior to start

# v0.2.16
* Log incoming messages at info level
* Add Source#touch method
* Rescue and log encoding errors on transmission (prevent fatal teardown)
* Add Message#touch proxy helper

# v0.2.14
* Always return `Smash` types when config value is `Hash`

# v0.2.12
* Prevent source configuration output at INFO level on build
* Keep all sources paused until all sources are built
* Add helper for performing hash conversions
* Support deep hash conversions (process through enumerables)

# v0.2.10
* Remove explicit JSON usage

# v0.2.8
* Make supporting library auto loaded as needed

# v0.2.6
* Provide arguments method alias for sources (#args)
* Allow configuration via directory and file merge

# v0.2.4
* Move receive starts out of processing loop
* Extract source name from arguments on setup
* Deep force smash type on conversion
* Add optional disablement of multiple callback matches

# v0.2.2
* Local loopback is optional and disabled by default
* Include Smash utility for Hash management
* Provide originating source to callback instances on initialization
* Add spec helpers
* Clean up custom supervisor implementation

# v0.2.0
* Remove `fog` from dependency list
* Add common spec helper for testing
* Only start sources if callbacks are defined
* Add custom supervisor with isolated registry
* Include auto-restart support
* Loop local messages internally instead of transmit/retrieve loop
* Use auto loading to clean things up

# v0.1.10
* Remove builtin sources
* Allow optional auto-symbolize
* Let `confirm!` accept extra parameters
* Add custom supervisor for future expansion

# v0.1.8
* Clean up requires
* Register sources by name for easy lookup
* Fix hash symbolizer to not symbolize non-strings
* Add confirmation helper method to message
* Start including tests

# v0.1.6
* Do not register callback if no worker is created

# v0.1.4
* Update `Source#send` to `Source#transmit`
* Add common util module for logging
* Allow SQS queues to be provided in named Hash form
* Allow sending to named SQS queues
* Make automatic response optional on HTTP source
* Use `Carnivore::Message` instead of bare hash for message passing

# v0.1.2
* Allow ARN based queue endpoints for SQS

# v0.1.1
* Update block implementation within callback
* Allow multiple queues on single SQS source
* Custom logging to provide instance source information

# v0.1.0
* Initial release
