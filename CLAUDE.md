# General Practices

In mobile-apps directory , we are building android, ios and web app. When doing a fix for one, make sure you do not break the flow for other apps, especially in authentication cases.

There are two web clients:
* Flutter web ( + otehr clients) in mobile-apps directory
* Svelte web client in web-client directory
Any web client fix should be done in both clients.

The the github/gitlab workflows should be using makefile targets to run test and build jobs so that it is easy to replicate issues.
