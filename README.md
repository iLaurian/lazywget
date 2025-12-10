# Raport de Proiect: LazyWGET

**Studenți:** Laurian Iacob, Antonie Belu

**Materie:** Instrumente și tehnici de bază in informatică  

---

## 1. Descrierea Problemei

### 1.1 Context
În contextul administrării sistemelor și al automatizării sarcinilor web, descărcarea recursivă a resurselor (Web Crawling) este o operațiune comună. Utilitarul standard `wget` oferă această funcționalitate prin flag-ul `-r`. Totuși, în anumite scenarii, descărcarea recursivă automată și neîntreruptă nu este de dorit, fie din motive de lățime de bandă, fie pentru a permite o inspecție intermediară a resurselor.

### 1.2 Obiectiv
Scopul acestui proiect este implementarea unui utilitar denumit `lwget` (Lazy Wget). Acesta trebuie să emuleze comportamentul recursiv al comenzii `wget` fără a utiliza opțiunea `-r`, folosind o abordare "leneșă" (lazy evaluation).

### 1.3 Specificul Problemei
Spre deosebire de o execuție continuă, `lwget` funcționează pe etape:
1.  **Prima execuție:** Descarcă o singură pagină (rădăcina) și identifică resursele referite.
2.  **Execuții ulterioare:** Procesează lista de resurse identificate anterior ("promisiuni"), le descarcă și extrage noi referințe pentru următoarea iterație.

---

## 2. Specificația Soluției

### 2.1 Cerințe Funcționale
Soluția propusă este un script Shell (`Bash`) care îndeplinește următoarele funcții:
* **Inițializare:** Acceptă un URL ca argument pentru a începe procesul de crawling.
* **Persistența Stării:** Salvează progresul pe disc în fișiere text (`visited.txt`, `promises.txt`) pentru a permite oprirea și reluarea execuției.
* **Parsing:** Analizează fișierele HTML descărcate pentru a extrage link-uri (`href`, `src`).
* **Filtrare:**
    * Se limitează la domeniul specificat inițial (nu iese pe link-uri externe).
    * Elimină duplicatele pentru a evita descărcarea redundandă.
* **Structura de directoare:** Recreează local ierarhia de directoare a site-ului sursă.

### 2.2 Mediu de Rulare
* **Platformă:** Linux.
* **Dependențe Software:** `bash`, `wget`, `grep`, `sed`, `cut`, `basename`, `sort`.

---

## 3. Design și Arhitectură

### 3.1 Algoritmul de Traversare
Arhitectura se bazează pe o parcurgere în lățime (BFS - Breadth-First Search) implementată iterativ. Coada de așteptare specifică BFS nu este ținută în memoria RAM, ci pe disc, sub forma fișierului `promises.txt`.

### 3.2 Gestionarea Stărilor (Fișiere Auxiliare)
Scriptul utilizează un director dedicat numit după hostname-ul țintei pentru a stoca datele:
* `visited.txt`: Funcționează ca un `Set` (mulțime). Conține toate URL-urile procesate deja, pentru a preveni ciclurile infinite.
* `promises.txt`: Coada de așteptare curentă. Conține URL-urile ce urmează a fi descărcate la următoarea rulare a scriptului.
* `promises.lock.txt`: Un fișier temporar folosit în timpul execuției curente pentru a separa lista de sarcini curente de noile promisiuni generate.

### 3.3 Fluxul de Execuție
1.  **Verificare Mod:** Scriptul verifică dacă există `promises.txt`.
    * *Nu există:* Este prima rulare -> se procesează URL-ul primit ca argument.
    * *Există:* Se redenumește `promises.txt` în `promises.lock.txt` și se procesează liniile din acesta.
2.  **Procesare per URL:**
    * Verifică unicitatea în `visited.txt`.
    * Descarcă resursa folosind `wget` (cu flag-uri pentru structură de directoare `-x`).
    * Dacă fișierul este HTML, extrage link-urile interne.
    * Normalizează link-urile (transformă căile relative în absolute).
    * Adaugă noile link-uri într-un fișier temporar de duplicate.
3.  **Curățare:** La finalul funcției, duplicatele sunt eliminate și lista unică este adăugată la noul `promises.txt`.

---

## 4. Implementare

Implementarea este realizată în Bash. Mai jos sunt detaliate aspectele tehnice critice.

### 4.1 Descărcarea Resurselor
S-a folosit comanda `wget` cu următorii parametri:
```bash
wget -P $ROOT_DIRECTORY -x -nH $resource_url
```

- **-P**: Specifică prefixul directorului de salvare.
- **-x**: Forțează crearea directoarelor (necesar pentru a replica structura serverului).
- **-nH**: (No Hostnames) Previne crearea unui director suplimentar cu numele domeniului.

## 4.2 Parsing HTML și Normalizare

Extragerea link-urilor se face folosind expresii regulate (Regex) prin `grep`, o soluție robustă pentru proiecte de scară mică, deși nu este un parser HTML complet.

### Bash

```bash
grep -ohiE '(href|src)="[^"]*"' $resource_directory/$file_name
```

Normalizarea URL-urilor tratează două cazuri principale:

- **Link-uri absolute față de root** (`/cale/fisier`): Se concatenează cu `ROOT_HOSTNAME`.
- **Link-uri relative** (`fisier.html`): Se concatenează cu URL-ul directorului curent.

## 4.3 Gestionarea Erorilor și Redirecționărilor

Scriptul presupune protocolul `http://` implicit. În cazul în care serverul necesită HTTPS, `wget` primește un cod **301 Moved Permanently** și urmărește automat redirecționarea către versiunea securizată. De asemenea, ieșirea standard de eroare (stderr) a comenzii `wget` este captată pentru a extrage numele fișierului salvat efectiv pe disc.

---

## 5. Experimente și Validare

### 5.1 Scenariu de Test

S-a testat scriptul pe un site static cu o structură ierarhică simplă (ex: pagina unei facultăți).

**Pasul 1: Inițializare**  
**Comanda**: `./lwget https://fmi.unibuc.ro`

**Rezultat:**  
S-a creat directorul `fmi.unibuc.ro`. În interior se află `index.html` și fișierele de stare. `visited.txt` conține URL-ul rădăcină.

**Pasul 2: Prima Iterație (Lazy)**  
**Comanda**: `./lwget`

**Rezultat:**  
Scriptul a citit link-urile din pagina principală (ex: "Anunțuri", "Cazare"). A descărcat paginile respective.

**Pasul 3: Verificare**  
Comanda `tree` a fost utilizată pentru a vizualiza structura:

```plaintext
fmi.unibuc.ro/
├── visited.txt
├── promises.txt
├── cursuri/
│   ├── index.html
│   ├── lab1.html
│   └── curs1.pdf
```

### 5.2 Performanță

Scriptul evită descărcarea redundantă prin verificarea `visited.txt` la începutul fiecărei funcții `parse-file`. Timpul de execuție depinde strict de viteza rețelei și de numărul de link-uri de pe pagină.

---

## 6. Concluzii

Proiectul LazyWGET a demonstrat cu succes posibilitatea simulării recursivității prin procese iterative și stocare pe disc.

### Lecții învățate

- **Parsing în Shell**: Deși posibil, parsing-ul HTML cu `grep` și `sed` este limitat și fragil la schimbări de formatare a codului sursă HTML.
- **State Management**: Separarea cozii de procesare (`promises.lock.txt` vs `promises.txt`) este crucială pentru a nu corupe datele în timpul rulării scriptului.
- **Interacțiunea Proceselor**: Captarea output-ului de la `wget` (care scrie bara de progres pe stderr) a necesitat redirectări specifice (`2>&1`) pentru a putea fi procesat de `grep`.

Soluția oferă o bază solidă pentru un crawler simplu, extensibil ulterior cu funcționalități de paralelizare sau filtrare avansată a tipurilor de fișiere (MIME types).