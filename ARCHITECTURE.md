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
│   │   ├── GameManager.gd       # [da fare] Gestione run (Ante, Match corrente, FC)
│   │   └── MatchController.gd   # [da fare] Loop partita (Passaggi, Tiri, Calcoli)
│   ├── entities/         # Controller nodi scena (Pedina Giocatore, Ostacolo)
│   └── resources/        # Definizioni CustomResource (I mattoncini dati)
│       ├── PlayerData.gd
│       ├── FormationData.gd
│       ├── TeamData.gd
│       ├── TalismanData.gd
│       ├── ArchetypeData.gd
│       ├── TrainingData.gd
│       └── BossData.gd        # [da fare] Boss e malus d'anta (GDD §8)
└── data/                 # I file .tres istanziati
    ├── formations/       # 4-4-2, 4-3-3, ecc. (coordinate pitch)
    ├── archetypes/       # Bomber, Muro, Baller, ecc.
    ├── talismans/
    ├── trainings/
    └── bosses/           # [da fare]

## 2. Convenzioni di scripts/core/

`GameCatalog`, `TeamGenerator` e `ActionResolver` sono classi **interamente statiche**
(`static func` / `static var` su `RefCounted`): si usano con `ClassName.metodo()`,
non vanno istanziate né registrate come autoload e non richiedono modifiche a
`project.godot`. Restano logica pura: nessun riferimento a nodi, scene o UI.

`GameManager` e `MatchController`, che devono conservare lo stato della run e della
partita, saranno invece gli unici autoload previsti.