# NyxSocial iOS (Objective-C, UIKit)

This is a **source bundle** for an iOS app that matches the backend API we built:
- Register/Login (JWT)
- Username search + friend requests/accept/list
- **E2EE chat** (client-side encrypt/decrypt; server sees only ciphertext)
- WebSocket realtime (`msg_deliver`) + call signaling (offer/answer/ice)

## IMPORTANT
This zip does **not** include a compiled Xcode project (`.xcodeproj`) because this environment can't run Xcode.
It contains **ready-to-add Objective-C files** + setup steps.

## Create the Xcode project
1) Xcode → File → New → Project → iOS → App
2) Interface: Storyboard (UIKit) and Language: Objective-C
3) Product Name: NyxSocial
4) Drag the included `NyxSocial/` folder into Xcode (check “Copy items”)

## Frameworks to add
Target → General → Frameworks:
- Security.framework
- CallKit.framework (optional)
- AVFoundation.framework (optional)

## Backend URLs
Edit `NyxSocial/Config.h`:
- kAPIBaseURL
- kWSBaseURL

Defaults:
- https://backendapi-sdj5.onrender.com
- wss://backendapi-sdj5.onrender.com

## WebSocket path
The WS endpoint is `/ws`, so final URL is:
`wss://<host>/ws?token=<JWT>`

## Calls
This bundle includes signaling + CallKit incoming call UI.
For real audio/video calls you must add WebRTC + TURN later.
