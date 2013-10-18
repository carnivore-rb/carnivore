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
