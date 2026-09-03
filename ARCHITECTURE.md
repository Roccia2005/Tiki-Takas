# ARCHITETTURA TECNICA - TIKI TAKAS (Godot 4.x / GDScript)

## 1. Struttura Cartelle di Progetto
res://
├── assets/
│   ├── fonts/
│   ├── sprites/          # Icone pedine, campo, carte mercato
│   └── audio/
├── scenes/
│   ├── main_menu/        # Menu Principale, Selezione Squadra, Enciclopedia
│   ├── match/            # Scena Campo di gioco, Portiere, HUD partita
│   └── shop/             # Calcio Mercato, Gestione Rosa/Panchina
├── scripts/
│   ├── core/             # Logica pura e indici statici (Ante, match, formule)
│   │   ├── GameCatalog.gd       # Indice statico delle risorse in data/ (GDD §9, §10)
│   │   ├── TeamGenerator.gd     # Generazione rosa e tratti squadra (GDD §2.3, §5, §7)
│   │   ├── ActionResolver.gd    # Formule passaggio/tiro e balistica (GDD §4, §4.1, §7)
│   │   ├── GameManager.gd       # Run roguelike: Ante, match, FC, boss (GDD §3, §7, §8)
│   │   ├── ShopManager.gd       # Calcio Mercato: prezzi, acquisti, allenamenti (GDD §6, §10)
│   │   └── MatchController.gd   # Loop azione: passaggi, tiri, punti parata (GDD §4, §7)
│   ├── entities/         # Controller nodi scena (Pedina Giocatore, Ostacolo)
│   └── resources/        # Definizioni CustomResource (I mattoncini dati)
│       ├── PlayerData.gd
│       ├── FormationData.gd
│       ├── TeamData.gd
│       ├── TalismanData.gd
│       ├── ArchetypeData.gd
│       ├── TrainingData.gd
│       └── BossData.gd        # Boss e malus d'anta (GDD §8)
└── data/                 # I file .tres istanziati
    ├── formations/       # 4-4-2, 4-3-3, ecc. (coordinate pitch)
    ├── archetypes/       # Bomber, Muro, Baller, ecc.
    ├── talismans/
    ├── trainings/
    └── bosses/           # Gli 8 boss di coppa (GDD §8)

## 2. Convenzioni di scripts/core/

`GameCatalog`, `TeamGenerator`, `ActionResolver` e `ShopManager` sono classi **interamente statiche**
(`static func` / `static var` su `RefCounted`): si usano con `ClassName.metodo()`,
non vanno istanziate né registrate come autoload e non richiedono modifiche a
`project.godot`. Restano logica pura: nessun riferimento a nodi, scene o UI.

`MatchController` è invece una classe istanziabile (`RefCounted`): va creata una
per partita e posseduta da `GameManager`, perché conserva lo stato mutabile del
match (fase, portatore di palla, contatori, punti parata). Anche qui resta logica
pura: nessun riferimento a nodi, scene o UI, l'interfaccia leggerà lo stato e i
Dictionary restituiti dai metodi.

`GameManager` segue la stessa regola di `MatchController`: è istanziabile
(`RefCounted`), va creato una volta per run e conserva lo stato del metagioco
(Ante, match corrente, Football Coins, boss sorteggiato, vetrina del mercato).
Possiede il `MatchController` della partita in corso e delega a `ShopManager` le
formule del Calcio Mercato; `ShopManager` non conosce `GameManager`, così la
dipendenza resta a senso unico ed evita i cyclic reference di GDScript. Nessun
autoload è quindi necessario: sarà la scena radice della UI a tenere il
riferimento all'istanza della run.

## 3. Convenzioni di scenes/match/ (layer visuale)

Il campo giocabile vive in `res://scenes/match/`, unica cartella dove sono
ammessi nodi `Node2D`/`Control`. Tutto il rendering è **programmatico** via
`_draw()`: nessun asset PNG, solo primitive vettoriali e `ThemeDB.fallback_font`.

| Script | Nodo base | Ruolo |
| --- | --- | --- |
| `PitchView.gd` | `Node2D` | Campo 1000x600, linee, cerchio, aree e porte a (0,300) / (1000,300) (GDD §9) |
| `PlayerToken.gd` | `Node2D` | Pedina vettoriale: colore per lato, ruolo, numero, Potenza efficace, raggio di contrasto |
| `BallToken.gd` | `Node2D` | Palla, segue `current_ball_carrier` / `ball_position` con interpolazione |
| `TrajectoryLine.gd` | `Node2D` | Linea di mira passaggio/tiro con stati valido / fuori Gittata / non valido / tiro |
| `ShotConeVisualizer.gd` | `Node2D` | Cono di tiro a 18 gradi e sagome ostruenti con malus (GDD §4, §4.1) |
| `MatchHUD.gd` | `Control` | Punteggio, passaggi, tiri, Potenza Azione, punti parata, messaggi flash |
| `MatchView.gd` | `Node2D` | Controller di scena: mouse drag&release, chiama `execute_pass()` / `execute_shot()` / `start_action()` |

`MatchView.tscn` è la scena eseguibile (`run/main_scene`) e monta
`PitchRoot` (offset 210,90 e scala 1.5 dentro il canvas 1920x1080) con
`PitchView`, `ShotCone`, `TrajectoryLine`, `TokensRoot`, `BallToken`, più un
`HUDLayer` (`CanvasLayer`) che contiene `MatchHUD`.

Regola invariata: **il layer visuale non contiene formule di gioco**. Legge lo
stato di `MatchController` e riusa `ActionResolver` (cono, gittata, malus) solo
per mostrare in anteprima gli stessi numeri che il core calcolerà. Il puntamento
converte il mouse in coordinate pitch con `to_local(get_global_mouse_position())`
e il bersaglio si individua per raggio, senza `Area2D` né fisica, così la scena
resta verificabile in headless.

## 4. Convenzioni di scenes/shop/, scenes/ui/ e scenes/main/ (Sprint 8)

Il ciclo roguelike completo vive nel layer visuale, che resta **sola lettura**
sullo stato del core: `GameManager` e `ShopManager` conservano ogni formula, le
schermate leggono e inoltrano l'input. Rendering sempre programmatico via
`_draw()` e `ThemeDB.fallback_font`, nessun asset esterno (GDD §12).

| Script | Nodo base | Ruolo |
| --- | --- | --- |
| `scenes/ui/UIStyle.gd` | `RefCounted` statico | Kit condiviso: palette, stelle rarità, `make_label/make_paragraph/make_button/make_option`, `draw_panel/draw_bar/draw_rule` |
| `scenes/ui/TitleScreen.gd` | `Control` | Menu iniziale: squadra, modulo, rosa, comandi, `start_requested` |
| `scenes/ui/MatchResultModal.gd` | `Control` | Esito match: punteggio, statistiche azione, Football Coins guadagnati, `continue_requested` |
| `scenes/ui/GameOverScreen.gd` | `Control` | Fine run: Ante raggiunta, match giocati/vinti, gol, boss, `restart_requested` |
| `scenes/ui/VictoryScreen.gd` | `Control` | Coppa alzata dopo l'Ante 6: trofeo vettoriale e albo d'oro, `menu_requested` |
| `scenes/shop/ShopCard.gd` | `Control` | Slot di vetrina: calciatore, talismano o allenamento con rarità, effetto e costo |
| `scenes/shop/ShopView.gd` | `Control` | Calcio Mercato: 3+2+1 slot, reroll progressivo, rosa con valori di cessione, `next_match_requested` |
| `scenes/main/Main.gd` | `Node` | Orchestratore della run: macchina a stati e proprietario del `GameManager` |

`Main.tscn` è la nuova scena eseguibile (`run/main_scene`). Monta `StageLayer`
con `MatchView` e `ShopView` istanziate (`autostart_demo_run = false`) e
`OverlayLayer` con le quattro schermate di stato; la commutazione avviene per
`visible` e `process_mode`, senza ricaricare l'applicazione.

Macchina a stati di `Main.Stage`:
`MENU -> MATCH / BOSS_MATCH -> SHOP -> MATCH ... -> GAME_OVER | VICTORY`.
`MatchView` notifica l'esito con `signal match_finished(won: bool)` (una sola
volta per partita collegata), `Main` lo registra con `record_match_result()` e
decide la fase successiva leggendo `run.run_state`: `SHOP_PHASE` apre il
mercato dopo il boss, `GAME_OVER` e `CUP_VICTORY` chiudono la run.
