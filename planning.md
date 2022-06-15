## Controls
- **`d`** to draw a card
- **`w`** to jump in
- not playable cards should be printed faint
- menu with cards left to right, select card slot with number
## UI mockup
```
              ┏━━━┓
Current Card: ┃ 7 ┃
              ┗━━━┛

You have 7 card(s):      these cards can have colored corners
┏━━━┓┏━━━┓┏━━━┓┏━━━┓┏━━━┓┏━━━┓┏━━━┓
┃ 3 ┃┃ 7 ┃┃ ⇄ ┃┃ ⊘ ┃┃ +2┃┃ +4┃┃▘ ▗┃
┗━━━┛┗━━━┛┗━━━┛┗━━━┛┗━━━┛┗━━━┛┗━━━┛

```
This requires smart linewrap to not break up the cards when they become plenty ➡︎ terminal dimensions must be set since detecting them is _pain_