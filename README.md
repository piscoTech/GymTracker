# Gym Tracker
Do you go to the gym and are tired of manually keep track of exercizes, sets and weight? With Gym Tracker you no longer need to carry a piece of paper and a pen around, even your phone if you have an Apple Watch:
- Create any number of workouts with fully customizable exercizes
- Archive workouts you no longer use
- Quickly start any non-archived workout
- Let the app guide you through exercizes and rests with timers and notifications
- Easily change the weight at the end of a set
- Crash safe: don't worry if something bad happens during a workout, your progress is saved and you can resume as soon as you reopen the app

At the end your workout is automatically saved inside the Health app, if you're using an Apple Watch with detailed heart rate and calories.

<!-- Support me by buying the app on the AppStore
[![Download on the AppStore](http://www.marcoboschi.altervista.org/img/app_store_en.svg)](https://itunes.apple.com/us/app/...) -->

## Project Setup
The framework `MBLibrary` referenced by this project is available [here](https://github.com/piscoTech/MBLibrary), version currently in use is [1.0.4](https://github.com/piscoTech/MBLibrary/releases/tag/v1.0.4(5)).

## Customization
General behaviour of the app can be configured via global variables in `Main iOS & watchOS.swift`:

* `maxRest`: Max rest period allowed in seconds, make sure it's a multiple of 30s.
* `authRequired`, `healthReadData` and `healthWriteData`: Used to save the latest authorization requested in `UserDefaults`, when `authRequired` is greater than the saved value the user will be promped for authorization upon next launch, increment this value when adding new data to be read or write to `healthReadData` or `healthWriteData`.