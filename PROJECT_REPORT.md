# Mumbai Metro Smart Companion - Project Report

## 1. Project Overview

Mumbai Metro Smart Companion is a Flutter-based mobile application designed to help Mumbai commuters plan metro journeys, view routes and timetables, book and manage tickets, check crowd conditions, receive travel alerts, and access metro announcements in one place. The app combines route intelligence, ticketing, profile management, multilingual support, and admin controls into a single metro travel assistant.

The project is built around a practical commuter workflow:
- choose a source and destination station
- discover the best route
- inspect live journey details
- book a ticket
- receive reminders before the destination
- store favorites and ticket history
- view alerts and admin announcements

## 2. Project Goals

The main goal of the application is to reduce the friction of daily metro travel by bringing together all essential commuter tools in one app. Instead of switching between multiple apps for route search, fare estimation, timetable lookup, and notifications, the user gets a unified experience inside a single interface.

The app also adds intelligent features such as:
- route suggestions based on the metro network
- crowd-level insights
- saved routes and recent searches
- ticket QR generation and verification
- smart transit alarms before the destination or interchange
- admin-pushed live alerts and emergency notices

## 3. Technology Stack

The app uses the following core technologies:

- Flutter and Dart for cross-platform mobile development
- Firebase Auth for login and signup
- Cloud Firestore for cloud persistence and live data sync
- SharedPreferences for local caching and offline continuity
- Provider for state management
- EasyLocalization for multilingual support
- flutter_local_notifications for reminders and transit alarms
- qr_flutter for generating ticket QR codes
- geolocator and url_launcher for commuter utility actions
- flutter_animate and google_fonts for interface polish and motion

## 4. Application Architecture

The app follows a layered structure:

- Presentation layer: screens for login, home, routes, map, timetable, tickets, profile, admin, and alarms
- State layer: providers that manage auth, metro data, tickets, favorites, crowd data, transit alarms, and admin controls
- Data layer: static metro data plus Firestore-backed user and admin collections
- Service layer: Firestore operations and local notification handling

This separation keeps the app organized and makes the feature set easier to maintain. The UI reacts to provider updates, while Firestore and local storage keep the data persistent across sessions.

## 5. Startup and User Flow

The application starts in [lib/main.dart](lib/main.dart). On launch, it:
- initializes Flutter bindings
- enables EasyLocalization
- sets system UI style and portrait orientation
- initializes Firebase using project-specific options
- loads SharedPreferences
- initializes the notification service
- opens the app with English, Hindi, and Marathi support

The splash screen in [lib/screens/splash/splash_screen.dart](lib/screens/splash/splash_screen.dart) decides where the user should go next:
- if not logged in, it opens the login screen
- if the user is an admin, it opens the admin dashboard
- otherwise, it opens the main metro navigation shell

## 6. Authentication System

Authentication is handled by [lib/core/providers/auth_provider.dart](lib/core/providers/auth_provider.dart), [lib/screens/auth/login_screen.dart](lib/screens/auth/login_screen.dart), and [lib/screens/auth/signup_screen.dart](lib/screens/auth/signup_screen.dart).

### What it does
- supports new account creation
- supports email/password sign-in
- stores login state locally
- keeps user name, email, and uid in SharedPreferences
- syncs with FirebaseAuth when Firebase is available
- supports logout and profile updates

### Special behavior
- the app treats admin@gmail.com as the admin account
- if Firebase is not available, the code still supports a fallback offline-like flow for demo continuity
- after login, user tickets and favorites are synced from Firestore

## 7. Main Navigation Structure

The main app shell is in [lib/screens/main_nav/main_navigation.dart](lib/screens/main_nav/main_navigation.dart).

It contains six tabs:
- Home
- Routes
- Map
- Timetable
- Tickets
- Profile

The app uses an IndexedStack, which means each screen stays alive when switching tabs. This improves performance and preserves user state, such as selected stations, open tabs, and loaded lists.

The navigation shell also includes a global emergency overlay. If Firestore marks an emergency alert as active, the app blocks the screen with a high-priority warning message.

## 8. Home Screen Features

The home page in [lib/screens/home/home_screen.dart](lib/screens/home/home_screen.dart) works as the app dashboard.

### Visible features
- greeting based on the current time of day
- user name display
- SOS button for urgent actions
- QR scanner shortcut
- profile shortcut
- quick route planner
- live announcements section
- peak-hour badges
- smart insights card
- quick statistics
- live ETA section
- popular stations list
- crowd alerts section

### Why it matters
The home screen gives commuters immediate access to the most common tasks without forcing them to dig through menus. It also surfaces contextual travel help, such as peak-hour warnings and nearby crowd information.

## 9. Route Planning System

Route planning is handled mainly by [lib/screens/routes/routes_screen.dart](lib/screens/routes/routes_screen.dart), [lib/screens/routes/station_search_screen.dart](lib/screens/routes/station_search_screen.dart), [lib/screens/routes/route_detail_screen.dart](lib/screens/routes/route_detail_screen.dart), and [lib/core/providers/metro_provider.dart](lib/core/providers/metro_provider.dart).

### What the user can do
- select source and destination stations
- swap source and destination
- search stations by name
- find routes across metro lines
- save routes to favorites
- view recent searches
- open route details
- book tickets from the chosen route

### Route intelligence
The route engine uses the built-in metro network defined in [lib/core/data/metro_data.dart](lib/core/data/metro_data.dart). It supports:
- direct routes on the same line
- interchange routes across connected lines
- deduplication of repeated paths
- fare calculation from number of stops
- travel time estimation from stop count and interchange count

### Route detail experience
The route detail screen shows:
- full journey summary
- line segments
- station-by-station timeline
- interchange indicators
- platform-side hints
- gate hints where available
- crowd icons for stations
- a save route toggle
- a book ticket button

## 10. Metro Data Model

The metro system is defined in [lib/core/models/models.dart](lib/core/models/models.dart) and [lib/core/data/metro_data.dart](lib/core/data/metro_data.dart).

### Main domain objects
- MetroLine: metro line metadata
- Station: station information and interchange details
- MetroRoute: a complete route from source to destination
- RouteSegment: one segment of a route on a single line
- MetroTicket: ticket record with QR-related and journey data
- SavedRoute: stored favorite route
- CrowdReport: crowd reporting record
- CrowdLevel: low, medium, high, unknown

### Data included
The app currently models four major lines:
- Blue Line
- Yellow Line
- Red Line
- Aqua Line

Each line includes station order, first train time, last train time, and service frequency.

## 11. Timetable and Schedule Features

The app offers timetable support in two screens:
- [lib/screens/routes/metro_schedule_screen.dart](lib/screens/routes/metro_schedule_screen.dart)
- [lib/screens/timetable/timetable_screen.dart](lib/screens/timetable/timetable_screen.dart)

### Metro schedule view
The schedule overview gives a simple per-line summary showing:
- line route
- first train
- last train
- train frequency

### Interactive timetable view
The timetable screen lets the user:
- choose a line
- pick FROM and TO stations on that line
- see estimated travel time
- view upcoming trains
- see the number of trains currently available
- read timetable overrides from Firestore if the admin has changed timings

This feature is useful for commuters who want to plan based on service availability rather than just route distance.

## 12. Metro Map Screen

The map screen in [lib/screens/map/map_screen.dart](lib/screens/map/map_screen.dart) presents a stylized metro network view.

### What it shows
- all lines or one selected line
- the station sequence on each line
- first and last train times
- frequency chips
- interchange station markers
- crowd labels per station
- legend for crowd levels and interchange symbols

### Important note
This is not a GPS map or a live geographic map. It is a structured line-based metro diagram that helps the user understand the network and station relationships more clearly.

## 13. Ticketing System

Tickets are managed across [lib/screens/tickets/tickets_screen.dart](lib/screens/tickets/tickets_screen.dart), [lib/screens/tickets/book_ticket_screen.dart](lib/screens/tickets/book_ticket_screen.dart), [lib/screens/tickets/ticket_detail_screen.dart](lib/screens/tickets/ticket_detail_screen.dart), [lib/screens/tickets/ticket_scanner_screen.dart](lib/screens/tickets/ticket_scanner_screen.dart), and [lib/core/providers/ticket_provider.dart](lib/core/providers/ticket_provider.dart).

### Ticket hub
The ticket hub separates tickets into:
- active tickets
- used or expired ticket history

### Booking options
The booking flow supports:
- regular tickets
- monthly pass tickets
- single journey tickets
- return journey tickets
- quantity selection up to multiple tickets

### Ticket details
Each ticket stores:
- ticket ID
- source
- destination
- fare
- stops
- estimated travel duration
- route summary
- lines taken
- booking time
- ticket type
- status

### QR code support
The ticket detail screen generates a QR code for active tickets. The QR code contains encoded journey and ticket information so it can be scanned at the gate.

### Ticket verification
The QR scanner screen provides a simulated scanning experience with manual ticket selection support. This is useful for development and for platforms where camera scanning is limited.

### Expiration logic
- regular tickets are valid for 24 hours
- monthly passes are treated as 30-day valid tickets
- expired tickets are automatically moved into history
- old Firestore tickets are cleaned up after 30 days

## 14. Payment Simulation

The booking flow uses [lib/screens/tickets/detailed_dummy_payment_screen.dart](lib/screens/tickets/detailed_dummy_payment_screen.dart) as a detailed simulated checkout screen.

### What it includes
- saved payment methods
- card payment entry
- UPI payment input
- net banking-style section
- fake security and processing animation

This gives the app a complete booking journey without connecting to a real payment gateway.

## 15. Favorites and Recent Searches

Favorites are managed by [lib/core/providers/favorites_provider.dart](lib/core/providers/favorites_provider.dart).

### Features
- save and remove routes
- store recent searches
- keep recent searches limited to the latest 10
- sync saved routes and searches to Firestore after login
- load cached favorites locally

### User value
This feature reduces repeated work for daily commuters. People can quickly reopen frequently used routes instead of entering the same stations again and again.

## 16. Crowd Reporting and Smart Insights

Crowd management is handled by [lib/core/providers/crowd_provider.dart](lib/core/providers/crowd_provider.dart).

### What it does
- generates default crowd levels based on peak and off-peak hours
- listens to Firestore station_status overrides from admin
- lets users report crowd levels manually
- calculates most crowded and least crowded stations
- provides smart travel recommendations

### Smart insights
The app shows guidance such as:
- best time to travel
- whether the app considers the current time peak or off-peak
- stations to avoid during rush hours
- travel recommendations based on the current hour

This turns the app from a static metro guide into a more predictive commuter assistant.

## 17. Transit Alarm and Notification System

A major smart feature is the transit alarm system in [lib/core/providers/transit_alarm_provider.dart](lib/core/providers/transit_alarm_provider.dart) and [lib/core/services/notification_service.dart](lib/core/services/notification_service.dart).

### What it supports
- destination alarms for direct trips
- interchange alarms for multi-line journeys
- countdown timers
- auto-reset after completion
- cancel alarm option
- notification scheduling with metro_alarm sound

### How it works
The user chooses a source and destination in the transit alarm screen. The app finds the best route, calculates travel time, and sets notifications to fire about 5 minutes before the destination or interchange.

### User benefit
This is especially useful for busy commuters who do not want to keep checking the phone during travel.

## 18. Profile and Account Features

The profile screen in [lib/screens/profile/profile_screen.dart](lib/screens/profile/profile_screen.dart) gives access to personal and app-level utilities.

### User information shown
- avatar initial
- user name
- user email
- trip count
- total spent
- favorite route count

### Quick actions
- saved routes
- recent searches
- ticket history
- announcements and alerts
- language selection
- about dialog
- metro line information
- smart transit alarm
- logout

### Edit profile
The edit profile page allows the user to change their display name. Email is shown as read-only.

## 19. Admin Dashboard

Admin functionality is available in [lib/screens/admin/admin_dashboard_screen.dart](lib/screens/admin/admin_dashboard_screen.dart) and [lib/core/providers/admin_provider.dart](lib/core/providers/admin_provider.dart).

### Admin tools
- publish metro announcements
- edit announcements
- delete announcements
- toggle peak-hour flags per line
- configure timetable overrides
- update station crowd level and facilities
- activate or deactivate emergency alerts

### Why this matters
The admin panel turns the app into a live metro operations and communication tool rather than only a passenger app. It can push updates into the user experience immediately through Firestore streams.

## 20. Firestore Data Flow

Firestore is centralized in [lib/core/services/firestore_service.dart](lib/core/services/firestore_service.dart).

### Key collections used
- users
- users/{uid}/tickets
- users/{uid}/savedRoutes
- users/{uid}/recentSearches
- announcements
- admin_config/peak_hours
- admin_config/emergency
- timetable
- station_status

### What is stored
- user profile data
- ticket history
- favorite routes
- recent searches
- public announcements
- emergency alerts
- timetable overrides
- station crowd and facility status

## 21. Localization and UI Styling

The app is already prepared for multilingual use with English, Hindi, and Marathi support. The text system uses EasyLocalization and translation assets in [assets/translations](assets/translations).

The UI uses a dark, metro-themed visual style with:
- strong gradients
- rounded cards
- line colors based on metro routes
- animated transitions
- icon-heavy navigation

This gives the app a polished and modern commuter look.

## 22. Limitations and Current Scope

The app is feature-rich, but it still has some practical scope limits:
- it does not use a live official metro API
- the map is a stylized network diagram, not a true GIS map
- ticket scanning is simulated in development-friendly form
- some screens still use hardcoded English text instead of full translation keys
- admin access is based on a fixed email address

These limits do not reduce the value of the project, but they are important to mention in a report because they show the current implementation boundary clearly.

## 23. Conclusion

Mumbai Metro Smart Companion is a complete Flutter-based metro travel assistant that combines navigation, route planning, ticket booking, QR management, crowd intelligence, transit alarms, announcements, and admin control in one app. The project demonstrates practical mobile app development with Firebase integration, responsive state management, local persistence, multilingual support, and a user-centered commuter workflow.

It is a strong academic or portfolio project because it does more than display information. It simulates a real commuting experience and connects multiple subsystems into one coherent metro companion app.
