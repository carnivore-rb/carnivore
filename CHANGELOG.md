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
