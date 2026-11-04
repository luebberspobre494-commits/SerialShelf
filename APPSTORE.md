# SerialShelf - App Store submission pack

Everything below is ready to paste into App Store Connect. English (U.S.) only.

## App Information

| Field | Value |
|---|---|
| Name | SerialShelf |
| Subtitle | Serial numbers & warranty |
| Primary language | English (U.S.) |
| Bundle ID | com.luebberspobre.serialshelf |
| SKU | SERIALSHELF001 |
| Category (primary) | Utilities |
| Category (secondary) | Productivity |
| Age rating | 4+ |
| Price | Free |

## Promotional text (170 chars)

Your gear is worth more than you remember. SerialShelf keeps every serial number, receipt and warranty end date in one place, on your phone, with no account and no cloud.

## Description

SerialShelf is a private, offline record of the things you own that carry a serial number and a warranty: phones, laptops, TVs, cameras, appliances, power tools, bikes.

Add an item once and keep the details that actually matter when something breaks: the serial number, the purchase date, how long the warranty runs, what you paid, the receipt photo, and where you bought it.

WHAT IT DOES

- Four sections: Items, Warranty, Reports, Settings
- Category filter and search across every item
- Warranty board split into Ending soon, In warranty, Expired
- Local reminders before a warranty runs out
- Receipt photo attached to each item
- Claim tracking: mark an item as claimed with date and note
- Reports: item count, expiring soon, claimed, total value, value still covered
- Category chart so you can see where the money went
- Export everything to CSV, import it back on another phone

BUILT FOR PRIVACY

No account. No sign up. No analytics. No ads. No server. Your data never leaves the device, and nothing is uploaded when you scan a label: text recognition runs on the iPhone itself.

WHO IT IS FOR

Anyone who has stood in a shop trying to remember whether the warranty expired last month or next month.

## Keywords

serial number,warranty,receipt,registry,inventory,gear,appliance,tracker,owner,proof

## Support and privacy URLs

- Support: https://luebberspobre494-commits.github.io/SerialShelf/support.html
- Privacy: https://luebberspobre494-commits.github.io/SerialShelf/privacy.html

## Screenshots

Take these on device, portrait, in this order:

1. Items - the list with five or six items, categories visible
2. Warranty - the three sections with a couple of items in Ending soon
3. Reports - the value cards plus the category chart
4. Item detail - serial number, warranty status, receipt photo

## App Review notes

No login required. No network calls. To review, tap + and add an item, or use Settings > Import CSV with the sample below.

name,brand,serial,category,purchaseDate,warrantyMonths,value,notes
MacBook Pro,Apple,C02XK1234,electronics,2025-03-14,24,2199,Work laptop
Espresso machine,Breville,BRV9921,appliance,2024-11-02,12,699,

## Guideline 4.3 answers

1. What does the app do that existing apps do not? It combines serial number capture (photo OCR on device), warranty countdown, claim tracking and a value report in one offline app. Most serial number apps are spreadsheets or cloud asset managers.
2. Is it a template or reskin? No. Written from scratch in SwiftUI with SwiftData, Vision OCR and Swift Charts.
3. Does it duplicate a flooded category? The serial number category on the US store is thin: about twenty apps, low review counts, one new entrant in the last year.
4. Does it have real utility? Yes: it answers "is this still covered" in one screen and produces a CSV you can hand to an insurer.
