# GAME DESIGN DOCUMENT (GDD) — TIKI TAKAS

## 1. INTRODUZIONE E VISIONE DEL GIOCO
- **Titolo:** Tiki Takas[cite: 2].
- **Ispirazioni:** *Balatro* e *Gambonanza*[cite: 2].
- **Genere:** Rogue-like calcistico strategico con oggetti potenzianti durante la partita e difficoltà incrementale[cite: 2].
- **Obiettivo Globale:** Giocare e superare i vari turni del mondiale per arrivare alla finale e vincere la coppa del mondo[cite: 2].
- **Obiettivo Singola Partita:** Battere il portiere avversario (che presenta una statistica di parata incrementale a seconda del livello affrontato) azzerandone i punti parata tramite i tiri prima di esaurire il numero di tiri concessi[cite: 2].

---

## 2. INTERFACCIA PRINCIPALE E MENU

### Schermata Iniziale
L'interfaccia principale presenta tre pulsanti di scelta[cite: 2]:
1. **Nuova Partita:** Porta alla schermata di selezione della squadra[cite: 2].
2. **Impostazioni:** Permette di modificare il volume dell'audio di gioco[cite: 2].
3. **Potenziamenti:** Menu enciclopedia diviso in tre sezioni (Archetipi, Allenamenti, Talismani)[cite: 2].
   - Mostra tutti i potenziamenti esistenti nel gioco[cite: 2].
   - Per gli elementi già sbloccati è visibile l'effetto[cite: 2].
   - Per gli elementi ancora da sbloccare l'effetto resta nascosto ed è visibile unicamente il metodo/sfida per sbloccarli[cite: 2].

### Selezione Nuova Partita (Menu Squadre)
- **Layout:** Mostra in alto lo schema/modulo con cui la partita inizierà e in basso la selezione della squadra[cite: 2].
- **Menu a Scorrimento Circolare:** Si vede solo la squadra attualmente selezionata[cite: 2]. Scorrendo a destra si passa alla successiva, a sinistra alla precedente[cite: 2]. Raggiunta l'ultima squadra, il carosello ricomincia dalla prima in modo continuo[cite: 2].
- **Pulsante "Inizia Partita":** Conferma la selezione e avvia la run[cite: 2].

## 2.3 SQUADRE DISPONIBILI E STATISTICHE INIZIALI

Ogni squadra determina il modulo di partenza, le risorse a disposizione per ogni match e una modifica passiva unica al proprio stile di gioco[cite: 2].

### 1. Standard
* **Modulo di Partenza:** 4-4-2[cite: 2].
* **Passaggi Disponibili:** 6.
* **Tiri Disponibili:** 4.
* **Descrizione:** *"Formazione classica e bilanciata, ideale per apprendere i fondamenti tattici."*
* **Metodo di Sblocco:** Disponibile fin dall'inizio[cite: 2].
* **Tratto Speciale:** Nessun modificatore passivo: rosa base con valori standard[cite: 2].

---

### 2. Italiana
* **Modulo di Partenza:** 5-3-2[cite: 2].
* **Passaggi Disponibili:** 4.
* **Tiri Disponibili:** 5.
* **Descrizione:** *"Catenaccio e contropiede: difesa impenetrabile e cinismo letale sotto porta."*[cite: 2]
* **Metodo di Sblocco:** Vinci una partita schierando una formazione composta da soli Difensori[cite: 2].
* **Tratto Speciale:** I Difensori partono con un bonus base di +3 alla Forza; i tiri scagliati dopo meno di 2 passaggi ricevono un bonus del +25% alla potenza finale.

---

### 3. Spagnola
* **Modulo di Partenza:** 4-3-3[cite: 2].
* **Passaggi Disponibili:** 10.
* **Tiri Disponibili:** 3.
* **Descrizione:** *"La forza del tuo gioco risiede nel tiki-taka: possesso prolungato fino a entrare in porta con il pallone."*[cite: 2]
* **Metodo di Sblocco:** Completa un match effettuando almeno 8 passaggi consecutivi prima di ogni tiro.
* **Tratto Speciale:** Ogni passaggio consecutivo completato all'interno della stessa azione aumenta il moltiplicatore del tiro finale del +5% (cumulabile fino al momento del tiro).

---

### 4. Portoghese
* **Modulo di Partenza:** 4-3-2-1 (Albero di Natale).
* **Passaggi Disponibili:** 5.
* **Tiri Disponibili:** 4.
* **Descrizione:** *"Tutti al servizio del Campione: una squadra costruita per esaltare un finalizzatore leggendario."*
* **Metodo di Sblocco:** Vinci la Coppa del Mondo segnando tutti i gol della competizione con il medesimo attaccante.
* **Tratto Speciale (Il Fuoriclasse):**
  * La punta centrale più avanzata (ATT) parte con **5 slot archetipi** disponibili (anziché il valore randomico standard)[cite: 2].
  * Alla generazione iniziale della squadra, tale attaccante riceve immediatamente l'archetipo **Bomber** assegnato al primo slot[cite: 2].
  * Se un compagno serve direttamente la punta centrale, quel passaggio trasferisce il 150% della propria Forza alla carica dell'azione.

---

### 5. Brasiliana
* **Modulo di Partenza:** 4-2-4.
* **Passaggi Disponibili:** 7.
* **Tiri Disponibili:** 4.
* **Descrizione:** *"Joga Bonito: fantasia pura, estro individuale e dribbling ubriacanti sulle corsie offensive."*
* **Metodo di Sblocco:** Raggiungi una Potenza Azione totale superiore a 150 punti in un singolo tiro durante l'Ante 1 o l'Ante 2[cite: 2].
* **Tratto Speciale:** Due attaccanti casuali all'avvio della run ricevono gratuitamente l'archetipo **Skiller**[cite: 2]; la percentuale di successo del *Tiro Fortunato* di tutta la squadra è aumentata permanentemente del +5% base[cite: 2].

### 6. Inglese
* **Modulo di Partenza:** 4-4-2 classico (con ali larghe).
* **Passaggi Disponibili:** 4.
* **Tiri Disponibili:** 5.
* **Descrizione:** *"Kick and Rush: lanci millimetrici dalle retrovie, duelli aerei e conclusioni dirette senza fronzoli."*
* **Metodo di Sblocco:** Segna un gol scagliando un tiro vincente direttamente dalla propria metà campo (distanza > 500 unità).
* **Tratto Speciale (Palla Lunga e Pedalare):**
  * La statistica **Gittata/Visione** del Portiere e di tutti i Difensori è aumentata permanentemente del +50%.
  * Un passaggio che scavalca completamente la linea di centrocampo (trasmissione diretta da POR/DIF a un ATT) conferisce un bonus secco di +15 punti alla Potenza Totale dell'Azione anziché il valore standard[cite: 2].
  * L'archetipo **Long Shot** ha probabilità quadruplicata di comparire nel Calcio Mercato[cite: 2].

---

## 3. STRUTTURA DEL MONDIALE E PROGRESSIONE
* **Formula del Torneo:** 6 Ante progressive composte ciascuna da 3 Match (2 preliminari + 1 Boss Match) per un totale di 18 partite.
- **Boss Match e Malus:** Ogni boss presenta un malus passivo che affligge il giocatore durante l'azione[cite: 2].
* **Ricompensa Fine Partita:**
  - Ricompensa in **Football Coins** (valuta di gioco)[cite: 2].
  * Vittoria Match standard: 4 Football Coins (FC)[cite: 3].
  * Vittoria Boss Match: 4 FC + 5 FC di bonus completamento (totale 9 FC)[cite: 2, 3].
  * Monete Residue: +1 FC per ogni passaggio non utilizzato, +2 FC per ogni tiro non utilizzato[cite: 3].

---

## 4. SCHERMATA DI GIOCO E REGOLE DEL MATCH

### Disposizione in Campo
- Campo orientato in orizzontale[cite: 2].
- Schieramento di **11 giocatori** appartenenti alla propria squadra[cite: 2].
- All'estrema destra è posizionata la porta avversaria difesa da un portiere[cite: 2].
- La potenza di parata del portiere avversario rappresenta l'obiettivo numerico da raggiungere/azzerare per superare l'anta[cite: 2].
- In alto è presente la panchina, che può contenere al massimo 3 giocatori

### Gestione Palla, Passaggi e Costruzione
- **Avvio Azione:** La prima azione della partita inizia sempre dai piedi del proprio portiere[cite: 2].
- **Scelta del Passaggio:** Il movimento della palla non è casuale ma deciso a comando dal giocatore selezionando il compagno destinatario[cite: 2].
- **Copertura e Distanza:** La fattibilità e la gittata del passaggio dipendono dalle statistiche del calciatore (es. chi possiede lancio lungo può servire qualsiasi compagno sul campo)[cite: 2].
- **Contatore Passaggi:** Ogni passaggio eseguito scala il contatore dei passaggi disponibili di 1[cite: 2]. A 0 passaggi rimasti non è più possibile passare la palla, salvo specifici potenziamenti[cite: 2].
- **Accumulo Potenza:** Ogni passaggio somma la **Forza** del calciatore che lo effettua alla potenza totale dell'azione in corso[cite: 2].

### Il Tiro in Porta
- Può essere eseguito in qualsiasi momento se il giocatore possiede la forza per coprire la distanza dalla porta[cite: 2].
- **Perdita di Potenza dalla Distanza:** I tiri scagliati da lontano perdono potenza in modo proporzionale alla distanza percorsa fino alla porta avversaria[cite: 2].
- **Esito del Tiro:** La potenza finale dell'azione viene sottratta ai punti parata del portiere[cite: 2]. Il contatore dei tiri disponibili cala di 1[cite: 2].
- **Condizioni di Fine Partita:**
  - *Vittoria:* Punti parata del portiere ridotti a 0[cite: 2].
  - *Sconfitta:* Tiri disponibili scesi a 0 con portiere ancora dotato di punti parata[cite: 2].

### Fattori di Casualità sul Tiro
- **Tiro Fortunato:** Percentuale di fare gol immediato anche se la potenza del tiro è inferiore alla parata residua del portiere (percentuale aumentabile con archetipi e talismani)[cite: 2].
- **Parata Fortunata:** Evento casuale che dimezza la potenza totale dell'azione calciata[cite: 2].

### Meccanica della Respinta (Post-Tiro)
Dopo un tiro respinto, la palla viene riassegnata a un compagno in base alla sua posizione sul campo (chi è più lontano dalla porta ha minori probabilità di riceverla) secondo le fasce[cite: 2]:
- **45% di probabilità:** a un Attaccante (possibilità di tap-in rapido)[cite: 2].
- **40% di probabilità:** a un Centrocampista[cite: 2].
- **15% di probabilità:** a un Difensore[cite: 2].

### Regola del Rendimento Decrescente sui Passaggi Multipli
All'interno della medesima azione (intervallo compreso tra una battuta e il tiro in porta), i giocatori possono ricevere e trasmettere la palla più volte, ma subiscono una penalità cumulativa sulla contribuzione alla carica:
* **1° Tocco nell'azione:** Aggiunge il **100%** della statistica Forza alla Potenza Totale dell'Azione[cite: 2].
* **2° Tocco nell'azione:** Aggiunge il **50%** della statistica Forza[cite: 2].
* **3° Tocco e successivi:** Aggiunge il **25%** della statistica Forza[cite: 2].
* **Comportamento degli Archetipi:** Gli effetti funzionali, di mobilità o di costo risorsa degli Archetipi (es. *Baller*, *Skiller*) rimangono pienamente attivi al 100% indipendentemente dal numero di tocchi effettuati[cite: 2]. Eventuali bonus numerici alla Forza derivanti da archetipi vengono invece scalati della stessa percentuale di penalità del tocco in corso.
* **Reset:** Il contatore dei tocchi individuali di tutti gli 11 giocatori si azzera istantaneamente non appena viene scagliato un tiro in porta[cite: 2].

### 4.1 Meccanica Avanzata Passaggi, Palla Persa e Ostacoli

#### Passaggi Fuori Gittata
* È consentito passare la sfera a compagni situati oltre la statistica `Gittata` del portatore.
* **Penalità:** Il passaggio subisce una perdita di potenza pari a:
  $$\text{Perdita} = (\text{Distanza} - \text{Gittata}) \times 0.05$$
* La perdita viene sottratta istantaneamente dalla **Potenza Totale dell'Azione**.

#### Condizione di Palla Persa (Turnover)
* Se in qualsiasi momento la Potenza Totale dell'Azione scende a **0 o meno** prima di aver calciato in porta:
  * L'azione fallisce all'istante senza produrre tiro.
  * Il contatore dei passaggi consumati non viene ripristinato.
  * La palla viene recuperata e riassegnata con **Respinta Difensiva**:
    * **60% probabilità:** assegnata a un Difensore.
    * **30% probabilità:** assegnata a un Centrocampista.
    * **10% probabilità:** assegnata a un Attaccante.

#### Ostacoli Dinamici in Campo (Difensori Avversari Passivi)
* A partire da **Ante 2**, compaiono sul terreno di gioco degli ostacoli mobili (sagome difensive avversarie) che aumentano con la difficoltà:
  * **Ante 1:** 0 ostacoli.
  * **Ante 2 – 3:** 1 ostacolo.
  * **Ante 4 – 5:** 2 ostacoli.
  * **Ante 6:** 3 ostacoli.
* **Collisione Traiettoria:** Se la linea geometrica di un passaggio o di un tiro interseca la sagoma di un ostacolo, l'azione subisce un malus secco di **-15 punti Potenza**. Se la potenza si azzera, scatta la condizione di Palla Persa.
* **Movimento Ostacolo:** A ogni passaggio completato, ciascun ostacolo compie un piccolo spostamento (30 unità) in direzione della palla, ma **senza mai cambiare la propria zona di reparto** (un ostacolo difensivo resta vincolato alla fascia Difesa, uno mediano al Centrocampo, ecc.).

---

## 5. LA ROSA: TITOLARI, PANCHINA E SOSTITUZIONI

### Scheda del Singolo Giocatore
- `Nome`[cite: 2].
- `Età`[cite: 2].
- `Ruolo` (`POR`, `DIF`, `CEN`, `ATT`)[cite: 2].
- `Potenza` (valore aggiunto al passaggio o al tiro)[cite: 2].
- `Distanza` (raggio entro cui trasmette/tira senza subire perdita di potenza)[cite: 2].
- `Slot Archetipi`: Numero di archetipi supportati contemporaneamente (da 0 fino a un massimo di 5; i giocatori con molti slot sono più rari)[cite: 2].
- `Allenamenti Ricevuti`: A ogni giocatore possono essere applicati infiniti allenamenti[cite: 2].
- **Generazione Iniziale:** All'avvio della run i giocatori vengono generati casualmente senza potenziamenti, a meno di tratti specifici della squadra scelta[cite: 2].

### Panchina e Finestra Cambi
- **Capienza:** Spazio riserve per massimo **3 giocatori** (vuoto a inizio partita)[cite: 2].
- **Gestione Acquisti:** Se c'è spazio entra in panchina; se la panchina è piena bisogna scegliere obbligatoriamente un giocatore dell'intera rosa da svincolare definitivamente[cite: 2].
- **Sostituzioni In-Game:** Effettuabili esclusivamente subito dopo un tiro in porta, prima di far ripartire l'azione[cite: 2].
- **Regola Cambio Definitivo:** Il giocatore sostituito esce e non può più rientrare per tutto il resto del round[cite: 2].
- **Reset:** La formazione titolare si ripristina all'assetto originario pre-partita a fine round[cite: 2].
- **Gestione Pre-Round:** Tra un round e l'altro è possibile spostare liberamente i calciatori dalla panchina al campo e viceversa[cite: 2].

---

## 6. CALCIO MERCATO (FINE ANTA)

### Listino e Rarità
I potenziamenti sono suddivisi in gradi di rarità da 1 a 3 stelle con costi fissi in Football Coins[cite: 2]:
- **1 Stella (★):** Costo 5 Monete[cite: 2].
- **2 Stelle (★★):** Costo 7 Monete[cite: 2].
- **3 Stelle (★★★):** Costo 15 Monete[cite: 2].
*(Alcuni potenziamenti compaiono nel mercato solo dopo essere stati sbloccati tramite sfide)*[cite: 2].

### Moduli Tattici (Licenze Tattiche)
Slot tattico a sé stante acquistabile nel mercato[cite: 2]. Sposta all'istante le coordinate e l'orientamento degli 11 slot del campo senza intaccare i cartellini individuali dei giocatori[cite: 2].
- Moduli supportati: `4-4-2` (base), `4-3-3` (Spagnola), `5-3-2` (Italiana), `4-5-1`, `5-2-1-2`, `4-1-2-1-2`, `4-2-3-1`[cite: 2].

### Talismani (Oggetti Permanenti di Squadra)
Modificatori passivi per l'intera squadra; se ne acquisti un altro dello stesso tipo si sovrascrive il precedente[cite: 2].
- **Talismano Possesso (★):** +2 passaggi disponibili, ma -1 tiro massimo per la squadra[cite: 2].
- **Talismano Egoista (★★):** Azzera i passaggi disponibili (0), ma aggiunge +3 tiri a disposizione[cite: 2].
- **Talismano Tuttocampo (★★★):** Permette di effettuare passaggi e tiri a tutto campo senza alcuna perdita di potenza dovuta alla distanza[cite: 2].

### Archetipi (Tratti Assegnabili al Singolo Giocatore)
Caratteristiche uniche inseribili negli slot liberi del giocatore (sostituibili se ne acquisti altri)[cite: 2]:
- **Bomber:** La potenza del giocatore viene moltiplicata per 1.5 ogni volta che segna un gol[cite: 2].
- **Muro:** Se riceve la palla a seguito di una respinta casuale post-tiro, la sua potenza aumenta di un range per l'intera durata di quell'azione[cite: 2].
- **Calamita:** Aumenta le probabilità che la palla finisca a lui al termine di un'azione respinta[cite: 2].
- **Skiller:** A ogni passaggio effettuato, la sua posizione in campo viene spostata automaticamente per avvicinarsi alla palla[cite: 2].
- **Baller:** Il passaggio effettuato da questo giocatore non consuma il contatore dei passaggi disponibili[cite: 2].
- **Long Shot:** Il tiro effettuato da questo giocatore non perde potenza a prescindere dalla distanza percorsa[cite: 2].

### Allenamenti (Card Consumabili per il Giocatore)
Potenziamenti permanenti cumulabili all'infinito[cite: 2]:
- **Bulk-up:** Aumenta la potenza del giocatore di un valore fisso[cite: 2].
- **Compleanno:** Fa avanzare l'età del giocatore di 1 anno, ricalcolando le sue prestazioni in base alla fascia anagrafica[cite: 2]:
  - *Sotto i 23 anni:* Forte aumento di potenza e probabilità di sbloccare un archetipo speciale[cite: 2].
  - *Tra 23 e 29 anni:* Guadagno di potenza standard[cite: 2].
  - *Dai 30 anni in su:* Perdita progressiva ed esponenziale di potenza all'aumentare dell'età[cite: 2].

### 6.1 Calcio Mercato: Slot Casuali, Prezzo Calciatori e Reroll

#### Layout e Generazione Negozio
* Il Calcio Mercato espone sempre **4 slot totali**[cite: 2].
* Ogni singolo slot estrae in modo completamente casuale da tutto il pool di elementi (Calciatore, Modulo Tattico, Talismano, Archetipo o Allenamento)[cite: 2].

#### Prezzo d'Acquisto dei Calciatori
Il costo in Football Coins (FC) di un cartellino calciatore al mercato è dinamico e calcolato con la seguente formula:
$$\text{Costo FC} = 4 + \text{BonusEtà} + \text{BonusForza} + \text{BonusGittata} + (3 \times \text{NumeroArchetipi})$$

* **BonusEtà:**
  * Età 17 – 22 anni (giovane talento): +2 FC.
  * Età 23 – 30 anni (pieno della carriera): +1 FC.
  * Età 31 – 40 anni (veterano): +0 FC.
* **BonusForza:** $+1\text{ FC}$ per ogni 5 punti di Forza oltre il minimo di ruolo (es. Forza 20 = +3 FC).
* **BonusGittata:** $+1\text{ FC}$ se la Gittata supera le 350 unità.
* **Archetipi:** $+3\text{ FC}$ per ciascun archetipo già presente negli slot del giocatore.

#### Meccanica Reroll Negozio
* Permette di rimescolare tutti gli slot non ancora acquistati.
* **Costo base:** 2 FC.
* **Incremento progressivo:** aumenta di +1 FC per ogni reroll consecutivo all'interno della stessa visita (2 FC $\rightarrow$ 3 FC $\rightarrow$ 4 FC...). Il costo si resetta a 2 FC all'inizio del mercato successivo.

## 7. BILANCIAMENTO NUMERICO E PROGRESSIONE

### Statistiche Base dei Calciatori
* **Età:** Compresa sempre tra **17 e 40 anni** (inclusi entrambi gli estremi) per qualsiasi giocatore generato[cite: 2].
* **Risoluzione Spaziale:** Campo orizzontale parametrizzato su scala 0 – 1000 unità (0 = linea di fondo difensiva, 1000 = linea di porta avversaria)[cite: 2].

| Ruolo | Potenza Base (Carica) | Gittata Base (Unità) | Ruolo Tattico Primario |
| :--- | :---: | :---: | :--- |
| **Portiere (POR)**[cite: 2] | 3 – 5 | 300 – 450 | Avvio manovra, primo tocco garantito[cite: 2] |
| **Difensore (DIF)**[cite: 2] | 4 – 8 | 250 – 400 | Disimpegno e scarico verso la mediana[cite: 2] |
| **Centrocampista (CEN)**[cite: 2] | 8 – 14 | 300 – 450 | Costruzione, smistamento e incremento carica[cite: 2] |
| **Attaccante (ATT)**[cite: 2] | 15 – 25 | 200 – 350 | Finalizzazione ravvicinata ad alto impatto[cite: 2] |

---

### Formula del Danno e Decadimento Distanza
Se la distanza tra il tiratore e la linea di porta supera la statistica **Gittata** del giocatore, il tiro subisce una perdita proporzionale fino a un minimo garantito del 20%[cite: 2]:

$$DannoEffettivo = PotenzaAzione \times \max\left(0.20,\, 1.0 - \frac{Distanza - Gittata}{500}\right)$$

* Se $Distanza \le Gittata$: il tiro infligge il **100%** della potenza accumulata[cite: 2].
* Se $Distanza > Gittata$: il moltiplicatore decresce linearmente di 0.002 per ogni unità eccedente, con soglia minima fissata al **20%**[cite: 2].

---

### Progressione Difficoltà: Punti Parata dei Portieri
Ogni fase (Ante) è strutturata su 3 match progressivi (2 preliminari + 1 Boss con malus attivo)[cite: 2]:

| Fase (Ante) | Nome Fase | Match 1 | Match 2 | Match 3 (Boss + Malus) |
| :--- | :--- | :---: | :---: | :---: |
| **Ante 1** | Girone di Qualificazione | 120 | 180 | **280** |
| **Ante 2** | Sedicesimi di Finale | 350 | 500 | **750** |
| **Ante 3** | Ottavi di Finale | 1.000 | 1.400 | **2.100** |
| **Ante 4** | Quarti di Finale | 3.000 | 4.200 | **6.500** |
| **Ante 5** | Semifinale | 9.000 | 13.000 | **20.000** |
| **Ante 6** | Finale Mondiale | 28.000 | 40.000 | **60.000** |

## 8. DEFINIZIONE DEI BOSS E CHALLENGE (MALUS D'ANTA)

La terza partita di ogni Ante (Match 3) è presidiata da un Boss che impone condizioni eccezionali o malus passivi per l'intera durata dell'incontro.

### Boss Ufficiali Approvati

* **Il Bunker (Catenaccio Estremo)**
  * **Descrizione:** La retroguardia avversaria si chiude a riccio nella propria trequarti difensiva.
  * **Effetto Meccanico:** I tiri effettuati da una distanza geometrica superiore a 350 unità dalla porta subiscono un'ulteriore penalità del -50% al danno calcolato.
  * **Impatto:** Obbliga a manovrare fino a ridosso dell'area prima di calciare.

* **Pressing Asfissiante**
  * **Descrizione:** L'avversario toglie ossigeno e tempo di giocata fin dal primo tocco.
  * **Effetto Meccanico:** Il contatore dei Passaggi Disponibili per la partita viene ridotto di -2 (minimo garantito: 1).
  * **Impatto:** Penalizza le azioni prolungate e premia giocate dirette o archetipi a costo zero.

* **Portiere Saracinesca (Il Gigante / DPS Check)**
  * **Descrizione:** Un portiere leggendario al culmine della forma fisica: una prova di pura potenza offensiva.
  * **Effetto Meccanico:** Non applica malus di gameplay, ma i suoi Punti Parata base sono aumentati del +50% rispetto al valore standard previsto per quel match.
  * **Impatto:** Mette alla prova la scalabilità numerica pura della rosa (richiede moltiplicatori alti, archetipi sinergici o combinazioni forti).

* **Terreno Pesante (L'Acquitrino)**
  * **Descrizione:** Campo fangoso e allagato che frena la rotolamento del pallone.
  * **Effetto Meccanico:** La statistica Gittata/Visione di tutti gli 11 giocatori in campo viene ridotta del -30%.
  * **Impatto:** Accorcia il raggio utile di passaggio e attiva prima la perdita di potenza sui tiri dalla distanza[cite: 2].

* **Marcatura a Uomo (La Gabbia)**
  * **Descrizione:** Raddoppio asfissiante sui riferimenti principali.
  * **Effetto Meccanico:** A ogni reset palla (post-tiro o a inizio azione), 2 compagni casuali di movimento vengono etichettati come "Marcati" e non possono ricevere passaggi per tutta l'azione corrente[cite: 2].
  * **Impatto:** Spezza i circuiti di passaggio prefissati e forza l'uso di linee secondarie.

* **Trappola del Fuorigioco**
  * **Descrizione:** Linea difensiva rivale coordinata a salire non appena la palla entra nel reparto offensivo.
  * **Effetto Meccanico:** Vietato il passaggio diretto tra attaccanti (ATT -> ATT)[cite: 2]. L'attaccante in possesso può solo tirare in porta o scaricare all'indietro (verso CEN o DIF)[cite: 2].
  * **Impatto:** Elimina le triangolazioni brevi d'area tra compagni di reparto.

* **Clima Ostile (Vento Contrario)**
  * **Descrizione:** Raffiche di vento frontali che ostacolano i tiri verso la porta ma favoriscono i fraseggi all'indietro.
  * **Effetto Meccanico:** La perdita di potenza oltre la Gittata raddoppia (il coefficiente di decadimento passa da 0.002 a 0.004 per unità). Di contro, i passaggi eseguiti verso sinistra (all'indietro) non consumano cariche passaggio.
  * **Impatto:** Incentiva il giro palla arretrato per riorganizzarsi prima del tiro finale.

  * **Portiere Para-Rigori (Reattivo dal Dischetto)**
  * **Descrizione:** Un estremo difensore implacabile nelle uscite basse e sui tiri ravvicinati, ma vulnerabile alle conclusioni da fuori.
  * **Effetto Meccanico:** I tiri scagliati da distanza ravvicinata (inferiore a 250 unità dalla porta) subiscono una penalità del -40% al danno finale calcolato. Di contro, le conclusioni dalla media-lunga distanza (superiori a 350 unità) non subiscono alcun decadimento di potenza da distanza per tutta la durata del match.
  * **Impatto:** Sovverte la tattica standard di infiltrazione in area, premiando i tiratori dalla distanza e l'uso dell'archetipo *Long Shot*[cite: 2].

  ## 9. MATRICE GEOMETRICA DEI MODULI TATTICI (COORDINATE PITCH)

Ogni modulo assegna coordinate `(X, Y)` assolute (su griglia orizzontale 1000×600) agli 11 slot in campo. Quando si cambia modulo, i calciatori occupano lo slot del rispettivo ruolo mantenendo l'ordine di schieramento.

---

### 1. Modulo 4-4-2 (Classico)
* **Slot 1 (POR):** (60, 300)
* **Slot 2 (DIF - Terzino SX):** (230, 100)
* **Slot 3 (DIF - Centrale SX):** (210, 230)
* **Slot 4 (DIF - Centrale DX):** (210, 370)
* **Slot 5 (DIF - Terzino DX):** (230, 500)
* **Slot 6 (CEN - Esterno SX):** (480, 90)
* **Slot 7 (CEN - Mediano SX):** (450, 240)
* **Slot 8 (CEN - Mediano DX):** (450, 360)
* **Slot 9 (CEN - Esterno DX):** (480, 510)
* **Slot 10 (ATT - Seconda Punta):** (780, 240)
* **Slot 11 (ATT - Prima Punta):** (810, 360)

---

### 2. Modulo 4-3-3 (Spagnola)
* **Slot 1 (POR):** (60, 300)
* **Slot 2 (DIF - Terzino SX):** (240, 90)
* **Slot 3 (DIF - Centrale SX):** (210, 230)
* **Slot 4 (DIF - Centrale DX):** (210, 370)
* **Slot 5 (DIF - Terzino DX):** (240, 510)
* **Slot 6 (CEN - Mezzala SX):** (500, 180)
* **Slot 7 (CEN - Regista Basso):** (420, 300)
* **Slot 8 (CEN - Mezzala DX):** (500, 420)
* **Slot 9 (ATT - Ala SX):** (770, 110)
* **Slot 10 (ATT - Punta Centrale):** (830, 300)
* **Slot 11 (ATT - Ala DX):** (770, 490)

---

### 3. Modulo 5-3-2 (Italiana)
* **Slot 1 (POR):** (60, 300)
* **Slot 2 (DIF - Terzino Fluidificante SX):** (270, 80)
* **Slot 3 (DIF - Braccetto SX):** (200, 190)
* **Slot 4 (DIF - Libero Centrale):** (180, 300)
* **Slot 5 (DIF - Braccetto DX):** (200, 410)
* **Slot 6 (DIF - Terzino Fluidificante DX):** (270, 520)
* **Slot 7 (CEN - Mezzala SX):** (470, 200)
* **Slot 8 (CEN - Mediano Centrale):** (440, 300)
* **Slot 9 (CEN - Mezzala DX):** (470, 400)
* **Slot 10 (ATT - Seconda Punta):** (790, 230)
* **Slot 11 (ATT - Centravanti):** (820, 370)

---

### 4. Modulo 4-3-2-1 (Portoghese / Albero di Natale)
* **Slot 1 (POR):** (60, 300)
* **Slot 2 (DIF - Terzino SX):** (230, 90)
* **Slot 3 (DIF - Centrale SX):** (210, 230)
* **Slot 4 (DIF - Centrale DX):** (210, 370)
* **Slot 5 (DIF - Terzino DX):** (230, 510)
* **Slot 6 (CEN - Mezzala SX):** (450, 180)
* **Slot 7 (CEN - Regista Difensivo):** (420, 300)
* **Slot 8 (CEN - Mezzala DX):** (450, 420)
* **Slot 9 (CEN - Trequartista SX):** (640, 210)
* **Slot 10 (CEN - Trequartista DX):** (640, 390)
* **Slot 11 (ATT - Punta Unica / Il Campione):** (840, 300)

---

### 5. Modulo 4-2-4 (Offensivo)
* **Slot 1 (POR):** (60, 300)
* **Slot 2 (DIF - Terzino SX):** (220, 90)
* **Slot 3 (DIF - Centrale SX):** (200, 230)
* **Slot 4 (DIF - Centrale DX):** (200, 370)
* **Slot 5 (DIF - Terzino DX):** (220, 510)
* **Slot 6 (CEN - Mediano SX):** (450, 240)
* **Slot 7 (CEN - Mediano DX):** (450, 360)
* **Slot 8 (ATT - Ala Sinistra):** (760, 100)
* **Slot 9 (ATT - Punta Centrale SX):** (820, 240)
* **Slot 10 (ATT - Punta Centrale DX):** (820, 360)
* **Slot 11 (ATT - Ala Destra):** (760, 500)

---

### 6. Modulo 4-5-1 (Catenaccio Mediano)
* **Slot 1 (POR):** (60, 300)
* **Slot 2 (DIF - Terzino SX):** (230, 90)
* **Slot 3 (DIF - Centrale SX):** (200, 230)
* **Slot 4 (DIF - Centrale DX):** (200, 370)
* **Slot 5 (DIF - Terzino DX):** (230, 510)
* **Slot 6 (CEN - Esterno SX):** (520, 90)
* **Slot 7 (CEN - Mezzala SX):** (480, 210)
* **Slot 8 (CEN - Mediano Schermo):** (430, 300)
* **Slot 9 (CEN - Mezzala DX):** (480, 390)
* **Slot 10 (CEN - Esterno DX):** (520, 510)
* **Slot 11 (ATT - Boa Solitaria):** (830, 300)

---

### 7. Modulo 4-1-2-1-2 (Rombo Stretto)
* **Slot 1 (POR):** (60, 300)
* **Slot 2 (DIF - Terzino SX):** (240, 80)
* **Slot 3 (DIF - Centrale SX):** (210, 230)
* **Slot 4 (DIF - Centrale DX):** (210, 370)
* **Slot 5 (DIF - Terzino DX):** (240, 520)
* **Slot 6 (CEN - Vertice Basso):** (390, 300)
* **Slot 7 (CEN - Mezzala SX):** (490, 190)
* **Slot 8 (CEN - Mezzala DX):** (490, 410)
* **Slot 9 (CEN - Trequartista / Vertice Alto):** (640, 300)
* **Slot 10 (ATT - Punta SX):** (810, 230)
* **Slot 11 (ATT - Punta DX):** (810, 370)

---

### 8. Modulo 4-2-3-1 (Bilanciato Moderno)
* **Slot 1 (POR):** (60, 300)
* **Slot 2 (DIF - Terzino SX):** (230, 90)
* **Slot 3 (DIF - Centrale SX):** (200, 230)
* **Slot 4 (DIF - Centrale DX):** (200, 370)
* **Slot 5 (DIF - Terzino DX):** (230, 510)
* **Slot 6 (CEN - Mediano SX):** (420, 230)
* **Slot 7 (CEN - Mediano DX):** (420, 370)
* **Slot 8 (CEN - Trequartista SX / Ala):** (650, 120)
* **Slot 9 (CEN - Trequartista Centrale):** (660, 300)
* **Slot 10 (CEN - Trequartista DX / Ala):** (650, 480)
* **Slot 11 (ATT - Terminale Offensivo):** (840, 300)

## 10. POTENZIAMENTI, TALISMANI E COMPRAVENDITA

### Limite Talismani e Gestione Slot
* La squadra può equipaggiare un massimo di **5 Talismani contemporaneamente**.
* Al raggiungimento del tetto massimo, per acquistarne un altro al Calcio Mercato è obbligatorio venderne o sovrascriverne uno attivo.

### Meccanica di Vendita Calciatori
* I giocatori presenti in panchina possono essere venduti liberamente nella schermata del Calcio Mercato.
* **Formula di Vendita:** Ricavo in Football Coins = `2 + (1 × numero di Archetipi) + (1 × numero di Allenamenti applicati)`.
* Un titolare non può essere venduto lasciando lo slot in campo sguarnito: deve prima essere scambiato con un panchinaro.

---

### 10.1 Catalogo Talismani Ufficiali

| Rarità | Nome | Costo | Effetto Meccanico |
| :---: | :--- | :---: | :--- |
| **★** | **Talismano Possesso**[cite: 2] | 5 | +2 passaggi disponibili, -1 tiro massimo per la squadra[cite: 2]. |
| **★** | **Gabbia Difensiva** | 5 | I Difensori ottengono permanentemente +2 alla Forza quando effettuano un passaggio. |
| **★** | **Guanto Rinforzato** | 5 | In caso di *Parata Fortunata*, il portiere subisce il 75% del danno (anziché il 50%)[cite: 2]. |
| **★** | **Fatturato Record** | 5 | Ottieni +1 Football Coin bonus per ogni giocatore venduto al Calcio Mercato. |
| **★★** | **Talismano Egoista**[cite: 2] | 7 | Azzera i passaggi a 0, ma aggiunge +3 tiri a disposizione della squadra[cite: 2]. |
| **★★** | **Lavagna Tattica** | 7 | Il costo di acquisto dei Moduli Tattici nel negozio scende permanentemente a 0 monete. |
| **★★** | **Terzo Tempo** | 7 | +1 Football Coin bonus per ogni tiro non utilizzato al termine di ogni match[cite: 2]. |
| **★★** | **Rinvio Telecomandato** | 7 | Nuove percentuali respinta post-tiro: 60% Attacco, 30% Centrocampo, 10% Difesa[cite: 2]. |
| **★★** | **Accademia Giovanile** | 7 | Tutti i calciatori under 21 generati o acquistati ricevono automaticamente +3 alla Forza base. |
| **★★** | **Tiro al Volo** | 7 | Se un'azione si conclude con un tiro al primo tocco dopo una respinta (tap-in), il danno è moltiplicato ×2. |
| **★★★** | **Talismano Tuttocampo**[cite: 2] | 15 | Passaggi e tiri non subiscono mai perdite di potenza legate alla distanza su tutto il campo[cite: 2]. |
| **★★★** | **Coppa dalle Grandi Orecchie** | 15 | Raddoppia i Football Coins ottenuti come premio alla vittoria di ogni Boss Match[cite: 2]. |
| **★★★** | **Pressing Totale** | 15 | Il rendimento decrescente sui passaggi multipli non scende mai al di sotto del 50% di Forza[cite: 2]. |

---

### 10.2 Catalogo Archetipi Ufficiali

* **Bomber:** La potenza del giocatore viene moltiplicata per 1.5 ogni volta che segna un gol[cite: 2].
* **Muro:** Se riceve la palla a seguito di una respinta casuale post-tiro, la sua potenza aumenta per l'intera durata di quell'azione[cite: 2].
* **Calamita:** Raddoppia la probabilità che la palla vagante finisca a lui dopo una respinta[cite: 2].
* **Skiller:** A ogni passaggio effettuato, la sua pedina avanza geometricamente di 50 unità verso la porta avversaria per quella partita[cite: 2].
* **Baller:** Il passaggio effettuato da questo giocatore non consuma il contatore dei passaggi disponibili[cite: 2].
* **Long Shot:** Il tiro effettuato da questo giocatore non subisce mai il decadimento di potenza dovuto alla distanza[cite: 2].
* **Regista:** Quando effettua un passaggio verso un compagno, conferisce al ricevente +50% di Gittata per il tocco successivo.
* **Assist Man:** Se serve un attaccante che calcia direttamente a rete al tocco successivo, il tiro riceve un moltiplicatore fisso ×1.3.
* **Bandiera:** Ottiene permanentemente +1 alla Forza per ogni Ante superata mantenendolo nella formazione titolare.
* **Veterano:** Se ha un'età pari o superiore a 33 anni, ha un costo d'acquisto dimezzato al mercato e conferisce +5 alla Forza se schierato con almeno due compagni under 23.
* **Opportunista:** Se riceve il pallone a meno di 200 unità dalla porta avversaria, la sua Forza base raddoppia (×2) per il tiro.
* **Metronomo:** I passaggi a corto raggio (distanza < 200 unità) effettuati da lui aggiungono il doppio della Forza (+100%).
* **Torre Aerea:** Se riceve la sfera da un passaggio lungo (distanza > 400 unità), il suo tiro successivo ottiene un bonus del +50% alla potenza.
* **Vivaio DOC:** Riceve permanentemente +2 alla Forza ogni volta che invecchia tramite l'allenamento *Compleanno* mantenendosi under 23.

---

### 10.3 Catalogo Allenamenti Ufficiali

* **Bulk-Up (★ - 5 Monete):** Aumenta in modo permanente la Potenza base del calciatore di +3[cite: 2].
* **Compleanno (★ - 5 Monete):** Fa avanzare l'età del calciatore di 1 anno, applicando un effetto anagrafico scalare[cite: 2]:
  * *Età < 23:* +6 alla Forza e 25% di probabilità di sbloccare un archetipo casuale gratuito[cite: 2].
  * *Età 23 – 29:* +3 alla Forza fissa[cite: 2].
  * *Età ≥ 30:* -3 alla Forza per ogni anno compiuto sopra i 29[cite: 2].
* **Occhio di Falco (★★ - 7 Monete):** Incrementa la Gittata/Visione del calciatore di +100 unità in modo permanente.
* **Masterclass Tattica (★★ - 7 Monete):** Converte e cambia in modo permanente il Ruolo del calciatore (`POR`, `DIF`, `CEN`, `ATT`).
* **Stage Giovanile (★★ - 7 Monete):** Ringiovanisce il calciatore di 3 anni (fino a un minimo invalicabile di 17 anni), preservandone le statistiche.
* **Slot Extra (★★★ - 15 Monete):** Sblocca permanentemente 1 slot archetipo vuoto aggiuntivo sul cartellino del giocatore (fino al limite massimo di 5 slot)[cite: 2].

### 11. SISTEMA DI SBLOCCO POTENZIAMENTI (ENCICLOPEDIA)

La maggior parte dei potenziamenti è **disponibile fin dal primo avvio** per garantire varietà immediata. Soltanto 4 elementi selezionati richiedono una semplice sfida introduttiva di scoperta per essere sbloccati e apparire nel mercato[cite: 2]:

| Categoria | Nome Elemento | Condizione di Sblocco Iniziale (Semplice) |
| :--- | :--- | :--- |
| **Talismano** | **Talismano Tuttocampo**[cite: 2, 3] | Vinci una partita effettuando un tiro da oltre 600 unità di distanza. |
| **Talismano** | **Coppa dalle Grandi Orecchie**[cite: 3] | Vinci il tuo primo Boss Match (qualsiasi Ante)[cite: 3]. |
| **Archetipo** | **Torre Aerea**[cite: 3] | Completa un'azione vincente usando almeno 2 lanci lunghi (>400 unità) consecutivi. |
| **Allenamento** | **Slot Extra**[cite: 2, 3] | Spendi almeno 15 FC complessivi all'interno di una singola visita al Calcio Mercato. |

*Tutti gli altri Talismani, Archetipi e Allenamenti presenti nel documento sono sbloccati di default[cite: 2, 3].*

---

### 12. DIREZIONE ARTISTICA, UI E STILE VISIVO (PER GODOT)
* **Stile Grafico:** 2D Top-down pulito con estetica "lavagna tattica moderna" mista a carte collezionabili (palette colori stile campo verde smeraldo scuro, linee gesso bianche/neon, pedine giocatori tonde minimali con numero e ruolo ben leggibili).
* **Risoluzione di Riferimento:** 1920×1080 (16:9), con pitch orizzontale posizionato centralmente occupante l'80% dello schermo e HUD compatto sui bordi.
* **Feedback e Juice:** Scia luminosa al passaggio della palla (che cambia colore o intensità all'accumulo di Potenza Azione), vibrazione dello schermo (screen shake) sui tiri potenti o pali/respinte del portiere.