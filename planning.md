## Controls
- **`d`** to draw a card
- **`w`** to jump in
- not playable cards should be printed faint
- menu with cards left to right, select card slot with number
- players must declare uno beforehand
## Game mockup
```bash
              ┏━━━┓
Current Card: ┃ 7 ┃
              ┗━━━┛
events: ═════════════════════════════════════════════
...
> nickname1 forgot to call "uno"
> You drew 7 cards

# playing direction
⬇︎════════════════════════════════════════════════════
[nickname1] has 4  cards # UI needs to expand dynamically
[nickname2] has 12 cards # depending on the number of players

You have 7 card(s):    # these cards can have colored corners
┏━━━┓┏━━━┓┏━━━┓ ┏━━━┓ ┏━━━┓┏━━━┓┏━━━┓
┃ 3 ┃┃ 7 ┃┃ ⇄ ┃ ┃ ⊘ ┃ ┃+ 2┃┃+ 4┃┃ ⨁ ┃
┗━━━┛┗━━━┛┗━━━┛ ┗━━━┛ ┗━━━┛┗━━━┛┗━━━┛
  ^ # selection cursor
════════════════════════════════════════════════════
[e]: draw card, [w]: jump in, [q]: call uno
```
This requires smart linewrap to not break up the cards when they become plenty ➡︎ terminal dimensions must be set since detecting them is _pain_
## Start mockup
```bash
```