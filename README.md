# macos-timesheet

Mac OS Script and LaunchAgent configuration for automated time tracking and time sheet generation.

The configuration in this repository will create a user level LaunchAgent that will run the `timesheet-tracking.sh` script on login and every 60 seconds. The script does retrieve user idle time, however currently the time tracking is only based on the locked state of the screen. A session starts when the user logs in or the screen unlocks, if the screen is locked for more than 60 seconds, then the session should be marked as ended.

## Getting Started

Clone this repository into somewhere under your `$HOME` directory. Then run the install script

```sh
./install.sh
```

## Known Issues

### Logout

Currently this script doesn't cater for shutdown or logoff. If a session isn't marked as ended before these events occur.
