Every time my dad and I traveled by train, the exact same scene played out.

It would be 3:30 AM. His phone alarm would blare loudly across the dark coach. He’d jolt awake in his berth, rub his tired eyes, look out the window into the pitch-black night — only to realize the train was stranded at an outer signal, delayed by two hours.

The worst part wasn't waking up early. It was what followed: he couldn't fall back asleep. If he slept, the train might start moving and he'd miss our destination. So he'd sit there awake, checking his watch every five minutes.

Seeing him lose sleep journey after journey made me ask a simple question:
Why are alarms tied to the clock when trains and buses run on geography?

A standard alarm rings whether your train is on time, early, or delayed by three hours.

That frustration led me to build RailAlarm — a battery-efficient, location-triggered wake-up companion built for train commuters, bus passengers, and long-distance travelers.

Here is what makes this problem tricky:
1. Battery drain: Running continuous GPS on an 8-hour journey drains a phone to 0%.
2. Connectivity dead zones: Trains constantly cross remote areas with zero network.
3. Silent mode: Travelers sleep with phones muted, suppressing standard notifications.

How RailAlarm handles it:
- Adaptive Safe Sleep Algorithm: Instead of constant GPS polling, RailAlarm calculates distance and speed to dynamically sleep between checks. An 8-hour trip consumes under 5% battery.
- 100% Offline-First: Bundles coordinates for 8,000+ railway stations and supports custom coordinates with zero internet required.
- Hardware Alarm Stream: Bypasses silent and DND modes so alerts sound reliably at your chosen lead distance (e.g., 2 km for buses, 10 km for express trains).
- Ergonomic Night UI: Dark glassmorphic design with high-contrast, large touch controls built for half-awake passengers in dark berths.

No traveler should have to sacrifice a night's sleep just to avoid missing a stop.

GitHub: https://github.com/Sreenandan2004/rail_alarm

Have you ever lost sleep or missed a station because of a delay? Would love to hear your thoughts and feedback!

#Flutter #MobileDevelopment #Dart #ProductDesign #OpenSource #TravelTech #BuildInPublic
