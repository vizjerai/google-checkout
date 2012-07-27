## Unreleased

### New Features
 - Allow cart contents to be read.

### Bug Fix
 - Fix not knowing if it was a google error or one caused by the gem.

## 0.3.0 / 2012-07-27

### Bug Fix
 - Changed Command.post to always return a Notification instead of raising an error.

## 0.2.0 / 2007-08-14

* Significant rewrite!
  * Added rSpec specifications.
  * Added level 2 integration for sending and
    and parsing notifications from Google.
  * Shipping temporarily hard-coded to 
    "Digital Download"
  * Added merchant-private-data for sending
    one's own tracking number to Google.
  * Defaults to live system but you can call
    GoogleCheckout.use_sandbox to use the
    sandbox instead.
  * Fixtures for Google commands and notifications.
