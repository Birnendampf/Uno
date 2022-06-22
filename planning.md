# UNO
<details><summary><b>Game Mockup</b></summary>
<p>

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
</p>
</details>

<h2>Card logic</h2>

| Cards | Chance |
| --- | --- |
| 1-9, ⊘, ⇄, +2 | $\frac{2}{27}$ |
| 0, ⨁, +4  | $\frac{1}{27}$ |

$RANDOM will be used to create a random number from 1 to 108
| RNG | card | ID | notes
| --- | --- | --- | --- |
| 1-2 | 1 | " 
| 3-4 | 2 | " |
| 5-6 | 3 | " |
| 7-8 | 4 | " |
| 9-10 | 5 | " |
| 11-12 | 6 | " |
| 13-14 | 7 | " |
| 15-16 | 8 | " |
| 17-18 | 9 | " |
| 19-20 | ⊘ | s | **s**kip |
| 21-22 | ⇄ | r | **r**everse |
| 23-24 | +2 | " | 
| 25 | 0 | " |
| 26 | ⨁ | p | **p**ick
| 27 | +4 | " |

<details><summary>image overview</summary>

![](https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/UNO_cards_deck.svg/1920px-UNO_cards_deck.svg.png)

</details>


each Card ID will be composed of the color letter (r/g/b/y) and the card number, e.g.: `r0`, `y+2`, `bp`
