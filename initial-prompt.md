I want to build an iOS client for Book Corners (Swift language and SwiftUI).

- Book Corners website: https://www.bookcorners.org
- Book Corners API: https://developers.bookcorners.org
- Book Corners backend source code: https://github.com/andreagrandi/book-corners

Before I describe what I want, it's important to understand HOW I want it.

I don't want you (the agent) to build the app straight away. I want to build it with your assistance.

Your initial task will be to create a plan for the features I want to implemement. The plan will have to be split into steps. Each step should be split in many sub steps in full details. Write it into `book-corners-ios-plan.md`

You will have to guide me as an interactive tutorial. You will start guiding me with things like "You need to add a Tab component" etc... each sub step will match to a few lines of code, ie "Now you need to add a `Button` with `"Submit"` label on it. You also need to set these other properties which are needed for..."

The most important goal here is my learning experience, not just getting things done.

If a component, library or technology hasn't been used yet, spend a couple of paragraph (even more if needed, but don't be too verbose) to introduce the subject and explain me stuff.

Assume I'm an experienced developer (I mainly write con in Python and Go, feel free to make comparison while you explain concepts) but pretty new to iOS development yet (apart from a couple of previous tutorials).

A personal advice (for the agent): I would find it very unlikely that you would be able to generate a full plan with also full details in a single shot. I would expect at most a plan like this one https://github.com/andreagrandi/book-corners/blob/master/book-corners-plan.md and before starting a new big step you take some time to further split it into many sub steps so that it becomes a tutorial.

Last but not least: if you have any doubts about my preferences for features, please ask me questions at any time and I can steer you to the right direction. I also may have forgot important features, so feel free to suggest anything related for an app like this one.

The flow when I will follow the tutorial will be:
- you tell me what is needed next
- I can ask you for "hint" or "hints"
- if something doesn't work or I can't fix a compilation error I may ask you to "fix"
- I may also ask you to "do it" or "implement" in case I want you to implement something for me
- I may ask you to "explain" and in this case you will tell me a few things about the component that is required or how a specific technology that we are about to use works (ie `SwiftData` etc...)
- I may ask you to "verify" what I did and you tell me what's wrong
- every time a step is done, I may ask you to "update plan" and you mark all the steps or sub steps as done ✅ (so it's easy next time to remember and resume from where we left)

## About Book Corners for iOS

I would like the app to be both a client to consult the existing libraries and a tool to improve the existing coverage and add new libraries.

### UI

The app should be organised in tabs:
- list of closest libraries (ordered by distance)
- a map of nearby libraries
- a button to submit a new library
- possibility to login/logout/register
- possibility to tap on a library (either from the map pins or from the list) and open the library detail
- possiblity to report an issue, send a picture for a library etc... if logged in

### Features

- a list of the closest libraries ordered by distance
- a map with the libraries (use Apple Maps first, we will evaluate later if the usage of MapLibre can make sense https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/)
- directions (using Apple Maps or Google Maps etc..) to reach the library
- initial splash screen
- possibility to login/register with either email/password or with Google or Apple logins
- submit a new library (if logged in)
- report an issue in a library (if logged in)
- add a photo for an existing library (if logged in)
- when submitting a new library and selecting a photo, the geo location should be read from the image itself first (if unavailable suggest the user to activate geolocation in Photos), and if unavailable rely on the user entering the address manually or moving the pin on the map. To geo reverse, the same API used by book corners can be used (Nominatim API)
- Photon API to auto complete addresses can be used too
- implement in app notification to notify a user when a library they submitted gets approved
- users with an admin role should also have access to a (normally hidden) dashboard where they can approve/reject submitted libraries
- a logged in admin should also receive an in app notification when another user submits a new library which needs to be approved
- if to implement anything of the above is missing from the backend API, please tell me and I will implement in book-corners.

## Architecture

- make sure you use MVVM pattern (or whatever is the suggested one from Apple for the current 2026 year)
- make sure the whole app is engineered following best practices (I want to learn in the right way)
- make sure the app is structured following the best practices
- always research about the latest available version of a method or library and avoid introducing deprecations
