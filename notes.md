# Notes
The first thing I did after reading the README of the project was to get up and running.

I have a working (vscode) devcontainer setup saved from a personal project.
I prefer working inside a devcontainer because this enables me to containerize the entire development setup and have ElixirLS working,
which is something that I haven't been able to do when using Docker on its own.

Even though I shouldn't write tests for this sample I'm going to add a test step in the CI/CD pipeline just to make sure I don't break anything.
I added a github actions workflow that runs the tests and deploys the application on fly.io on success.

Running the tests results in `40 tests, 9 failures`. So I'm going to remove the test step in the CI workflow as I'm not going to fix the tests.

First `npm install` resulted in an error `ENOTEMPTY: directory not empty, rmdir '/workspace/assets/node_modules/.unset-value.DELETE'`. Deleting the `node_modules` folder and rerunning the install did the trick.

As `fly status` returns info based on which project folder you're in, the dashboard widget should be added to the `show` page.

For `https://api.fly.io/graphql` to work you need to add an authorization header **with Bearer**:
`"Authorization": "Bearer YOUR_AUTH_KEY"`

For speed's sake I'm just going to display the info in a table below the "Process Groups" for now but I don't like how it looks.
The table overflows and requires you to scroll to see all the info.
Ideally you'd be able to see everything at a glance (on desktop at least).

At this point the data is loaded and displayed on the dashboard but only when you reload the page.
The sample description states that it should refresh automatically every X-seconds.
This can be trivially solved by treating our LiveView as a Genserver by sending a message to the LiveView process and in the handle_info (re)scheduling the next refresh.
By creating a separate `schedule_app_status_refresh` function that handles the sending of the message,
we can allow the refresh interval to be passed as a parameter.
This way we could, if we wanted to, let the user configure the refresh rate.

Since the allocations table has a good amount of columns, placing it below the "Process Groups" and "Timeline" cards
causes a significant whitespace gap to appear between the top of the "Deployment" card and the bottom of the "Process Groups card".
For this reason I move it to the top of the page.
This also gives the table some more room so all columns can be displayed without the need for scrolling.

The refresh is working but on the client side it's hard to tell if anything is happening.
Ideally I'd add a loading indicator but I'm afraid this would slow me down too much.
So I'm opting for adding an "updated at" indicator so the user can see how stale the data is.

I'm not sure what the different deployment statuses can be: successful and running?
Ideally the graphQL type would be an Enum instead of a String so the docs could list the possible statuses.

Showing the completed allocations or instances by default is a bad idea. This can quickly grow too large to have any use.
With this in mind I'm adding a toggle to switch whether or not to show completed allocations.

I'd like to have the user to be able to specify the refresh rate, but since I don't have enough time I'm adding a refresh button.

-----

## what I built and what I didn't build

### what I built
Reusing existing UI elements I display the info of the latest deploy in a "card". The card header contains the deployment status information as well as a "staleness" indicator. The body of this card contains a table that lists the allocations or instances of the latest deploy.

The data is reloaded every 5 seconds or when the user clicks the refresh button.
By default the completed deploys are not displayed. A toggle can be clicked to load them.

### what I didn't build
Initially I wanted to add a "copy to clipboard" hook so the user would be able to click either the shortId or a button next to it to copy the longId to the clipboard. Thinking this could be handy if you need the id for a `fly` command. But after doing some quick Googleing I found that `document.execCommand` (which is what you'd use to copy data to the clipboard) is deprecated and is being replaced with the Clipboard API. But support seemed spotty so I thought it wasn't worth the hassle.

Since an application needs to be deployed at least once for it to show up in the index page, I'm not adding an empty state for the allocations table.

## what I'd improve or fix if I had more time
- Fix the failing tests.
- Remove webpack and use esbuild instead if possible.
- there is no way to quickly check **why** a release failed.
- Allow user to specify refresh rate.
- Add sorting and filtering to the deployment status table.
- Extract some common ui elements into components. The "running" badge or the toggle for example are good candidates.
- Staleness indicator time formatting is off (H:m instead of HH:mm).
- The Desired status vs Actual status don't quite match. I'd make some sort of mapping function (stop vs complete)
- Make the allocations table responsive.
- The "show completed deploys" toggle doesn't limit its results. This should be added to prevent large amounts of data being loaded.

## how I'd determine if this feature is successful

- It displays all the info that the `fly status` command returns.
- The info is displayed in a clear and concise manner.
- The data is reloaded automatically.
- The UI is responsive.
