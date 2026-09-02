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
│   ├── core/             # Autoload singleton e logica pura
│   │   ├── GameManager.gd       # Gestione run (Ante, Match corrente, FC)
│   │   └── MatchController.gd   # Loop partita (Passaggi, Tiri, Calcoli)
│   ├── entities/         # Controller nodi scena (Pedina Giocatore, Ostacolo)
│   └── resources/        # Definizioni CustomResource (I mattoncini dati)
│       ├── PlayerData.gd
│       ├── FormationData.gd
│       ├── TalismanData.gd
│       ├── ArchetypeData.gd
│       ├── TrainingData.gd
│       └── BossData.gd
└── data/                 # I file .tres istanziati
    ├── formations/       # 4-4-2, 4-3-3, ecc. (coordinate pitch)
    ├── archetypes/       # Bomber, Muro, Baller, ecc.
    ├── talismans/
    ├── trainings/
    └── bosses/