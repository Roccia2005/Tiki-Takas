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
