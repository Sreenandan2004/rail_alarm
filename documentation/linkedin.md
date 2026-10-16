# LinkedIn Post: The Story Behind RailAlarm 🚆✨

---

### Post Copy (Ready to Paste)

For as long as I can remember, every time my dad and I traveled by train, the exact same scene would play out. 

It would be 3:30 AM. His phone alarm would blare loudly through the quiet coach. He’d jolt awake in his berth, rub his tired eyes, and look out the cold, dark window into the pitch-black night — only to realize the train was stranded at an outer signal, delayed by two hours. 😔

The worst part wasn't just waking up early. It was what happened next: he couldn't fall back asleep. If he slept, the train might start moving and he'd miss our destination. So he'd just sit there awake, exhausted, checking his watch every five minutes.

Seeing my dad lose his sleep journey after journey planted a question in my mind:
**Why are our alarms tied to the clock when trains and buses run on geography?**

A clock alarm doesn't care if your train is running on time, early, or delayed by three hours. It rings anyway.

That personal frustration is the core inspiration behind **RailAlarm** — a smart, battery-efficient, location-triggered wake-up companion I built for railway commuters, bus passengers, and road travelers. 📍🔋

---

### 💡 Why Building This Was Harder Than It Looked:
When I first started designing it, I realized standard location apps fail travelers in three big ways:
1. **Aggressive Battery Drain:** Keeping high-accuracy GPS running continuously on a 6 to 10-hour journey drains phone battery to 0% before you arrive.
2. **Connectivity Dead Zones:** Railway tracks and highways cross remote forests and valleys with zero cellular reception. The app had to be 100% offline-first.
3. **Silent Mode Suppression:** Passengers sleep with their phones on Silent or DND, which silences normal push notifications.

---

### 🛠️ How RailAlarm Solves It:
- **Adaptive "Safe Sleep" Algorithm:** Instead of burning the battery with continuous GPS polling, RailAlarm calculates your distance and speed to dynamically sleep between checks ($\Delta t = \frac{D - D_{\text{lead}}}{V_{\text{max}}}$). An 8-hour journey consumes less than 5% total battery.
- **100% Offline-First:** Bundles coordinates for 8,000+ Indian Railways stations and supports direct coordinate inputs for highway and rural bus stops with zero internet.
- **Hardware Alarm Stream (`STREAM_ALARM`):** Overrides silent profiles so the alert rings reliably when you enter your chosen lead boundary (2 km for city buses, 10 km for express trains).
- **Designed for the Half-Awake Traveler:** An organic, calm glassmorphic dark theme featuring large, unmistakable Snooze and Stop controls so you never fumble in a dark coach.

---

### ❤️ The Goal:
No parent, commuter, or traveler should have to sacrifice their sleep just to make sure they don't miss their stop. 

I’m currently rolling out our adaptive tracking engine and would love to hear from fellow travelers:
- Have you ever lost sleep or missed a station due to an unexpected delay?
- What warning distance or time do you prefer before your stop?

Drop a comment or DM me if you’d like to try the early build! 👇

---

**Tech Stack:** Flutter, Dart, Isar Database, Geolocator, Clean Architecture

#Flutter #MobileDevelopment #ProductStory #IndieDev #Commute #TravelTech #Dart #UIUX #CleanArchitecture #BuildInPublic #OpenSource
