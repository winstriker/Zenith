# The iOS issue

**Short answer: Zenith runs on iOS, but it isn't on the App Store, and it won't be for now.**

## Is the app ready for iOS?

Yes. Zenith is written in Flutter, and the parts that were Android-only have an iOS version too.
The minimum version is **iOS 15**, because the photo picker plugin requires it.

It has been tested on an iPhone 12 with iOS 27: the logbook PDF export, saving a backup to the Files app and restoring from it, the notification permission and scheduling a reminder, and GPS recording, which kept receiving positions with the screen locked.

What's still left before a release:

- **More testing on real iPhones**, especially longer recorded flights and older iOS versions.

## So why isn't there an iOS version?

The code isn't the hard part. Distribution is.

A logbook is a legal record of your flying. It has to be on your phone **all the time**: at the airfield, during a ramp check, years from now. An app that might stop opening next week isn't good enough for that.

On Android anyone can install Zenith from an APK and it keeps working. On iOS there's no equivalent:

- A free Apple ID can sideload an app, but the signature **expires after 7 days**. After that the app won't open until you rebuild and reinstall it from a Mac.
- TestFlight builds expire after 90 days and still need a paid account.
- The only way to keep the app reliably installed is to publish it on the **App Store**, which needs the **Apple Developer Program at 99 USD / year**, every year, for as long as the app exists.

## Why don't I put the money?

Zenith is free, open source and has no ads, no subscriptions and no tracking. It makes no money, and I want to keep it that way.
It was born because i didn't find a valid alternative online, all of them offered limited features or a limited number of logbook entries before requiring a costly subscription. You might think: "Well, a pilot can pay more than 200$/hr for a plane, they wouldn't even notice 5+$/month going out of their pocket" but as a student pilot myself i would prefer having a couple bucks spare rather than giving them away.

I'm also saving every cent I can for flight school. A recurring yearly fee just to keep the app on the App Store for Apple devices, that i don't use, isn't something I want right now.

## How you can help

If you'd like to see Zenith on the iPhone:

- **Sponsor the project.** Once the yearly Apple fee is covered by recurring sponsors, I'll publish Zenith to the App Store.
  Think of it this way: if you can afford to support Zenith, you're giving pilots who can't a free, full-featured digital logbook.

  [![Support Zenith on Ko-fi](https://img.shields.io/badge/Support_Zenith_on_Ko--fi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/winstriker)

- **Test it.** If you have a Mac and an iPhone, build it yourself and report what breaks.
- **Spread the word.** More users means more chances of finding sponsors.

Thank you for understanding. Hope you CAVOKs every day! ✈️
