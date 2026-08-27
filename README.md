# Linux CMD Movie Dataset Analysis

This project uses Linux command-line tools such as `awk`, `sort`, `uniq`, `cut`, and `head` to clean and analyze the TMDB movie dataset.

Source: https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv

---

## TMDB Movies Dataset — Column Index Mapping

The dataset contains **21 columns**. Since the analysis uses `awk -F','`, the following mapping is used throughout the project:

```text
$1  = id
$2  = imdb_id
$3  = popularity
$4  = budget
$5  = revenue
$6  = original_title
$7  = cast
$8  = homepage
$9  = director
$10 = tagline
$11 = keywords
$12 = overview
$13 = runtime
$14 = genres
$15 = production_companies
$16 = release_date
$17 = vote_count
$18 = vote_average
$19 = release_year
$20 = budget_adj
$21 = revenue_adj
```

---

# Data Cleaning / Pre-processing

## CSV Data Issues

Before processing the dataset, several data quality issues were identified:

1. Some fields contain commas `,` inside double quotation marks `"..."`. Using `awk -F','` directly would therefore cause column shifting.
2. Some values in the `overview` column contain newline characters, causing a single movie record to span multiple lines.
3. The dataset may contain duplicate movie records, so duplicate IDs need to be checked and removed.

---

## Step 1 — Remove Newlines Inside Movie Records

```bash
awk '
{
    if (record == "")
        record = $0
    else
        record = record " " $0

    temp = record
    quotes = gsub(/"/, "", temp)

    if (quotes % 2 == 0) {
        print record
        record = ""
    }
}
END {
    if (record != "")
        print record
}
' tmdb-movies.csv > movies_no_newline.csv
```

The original file contained **10,880 lines**.

After combining records that contained embedded newlines, the file contained **10,867 lines**.

---

## Step 2 — Remove Duplicate Movies

The `id` column is used to identify duplicate movie records.

```bash
awk -F',' 'NR == 1 || !seen[$1]++' movies_no_newline.csv > movies_no_duplicate.csv
```

After removing duplicate IDs, the dataset contained **10,866 lines**.

---

## Step 3 — Replace Commas Inside Double Quotes

Some text fields still contain commas inside `"..."`.

Since `awk -F','` treats every comma as a field separator, commas inside quoted text are replaced with spaces.

```bash
awk '
{
    inquote = 0

    for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)

        if (c == "\"") {
            inquote = !inquote
            printf "%s", c
        }
        else if (c == "," && inquote) {
            printf " "
        }
        else {
            printf "%s", c
        }
    }

    printf "\n"
}
' movies_no_duplicate.csv > movies_clean.csv
```

The cleaned dataset is now ready for processing with:

```bash
awk -F','
```

---

# Data Processing / Tasks

## Task 1 — Sort Movies by Release Date in Descending Order

Sort movies from newest to oldest and save the result to a new file.

```bash
{
    head -n 1 movies_clean.csv

    awk -F',' 'NR > 1 {
        split($16, date, "/")
        printf "%04d%02d%02d,%s\n", $19, date[1], date[2], $0
    }' movies_clean.csv |
    sort -t',' -k1,1nr |
    cut -d',' -f2-
} > movies_sorted_by_date.csv
```

**Result:**

* Newest release date: `12/31/15`
* Oldest release date: `1/1/60`

For example, `Martyrs` was released on `12/31/15`, while `The Unforgiven` was released on `1/1/60`.

---

## Task 2 — Filter Movies with an Average Rating Above 7.5

```bash
awk -F',' 'NR == 1 || $18 > 7.5' movies_clean.csv > movies_rating_over_7.5.csv
```

**Result:**

There are **350 movies** with an average rating above `7.5`.

---

## Task 3 — Find Movies with the Highest and Lowest Revenue

### Highest Revenue

```bash
awk -F',' '
NR == 2 {
    max = $5
    movie = $6
}

NR > 2 && $5 > max {
    max = $5
    movie = $6
}

END {
    print "Movie:", movie
    print "Revenue:", max
}' movies_clean.csv
```

**Result:**

```text
Movie: Avatar
Revenue: 2781505847
```

Therefore, **Avatar** has the highest revenue in the dataset.

### Lowest Revenue

```bash
awk -F',' '
NR == 2 {
    min = $5
    movie = $6
}

NR > 2 && $5 < min {
    min = $5
    movie = $6
}

END {
    print "Movie:", movie
    print "Revenue:", min
}' movies_clean.csv
```

This returns a revenue of `0`.

A revenue value of `0` may represent missing or unknown data rather than an actual revenue of zero. Since many movies may have this value, the next step is to find the lowest revenue greater than `0`.

```bash
awk -F',' '
NR > 1 && $5 > 0 {
    if (min == "" || $5 < min) {
        min = $5
        movie = $6
    }
}

END {
    print "Movie:", movie
    print "Revenue:", min
}' movies_clean.csv
```

**Result:**

```text
Movie: Shattered Glass
Revenue: 2
```

To check whether any other movies also have a revenue of `2`:

```bash
awk -F',' 'NR > 1 && $5 == 2 {
    print "Movie:", $6
}' movies_clean.csv
```

**Result:**

```text
Movie: Shattered Glass
Movie: Mallrats
```

Therefore, the movies with the lowest non-zero revenue are:

* `Shattered Glass`
* `Mallrats`

Revenue:

```text
2
```

---

## Task 4 — Calculate the Total Revenue of All Movies

```bash
awk -F',' '
NR > 1 {
    total += $5
}

END {
    printf "Total Revenue: %.0f\n", total
}' movies_clean.csv
```

**Result:**

```text
Total Revenue: 432719225875
```

Equivalent to:

```text
432,719,225,875
```

---

## Task 5 — Top 10 Movies with the Highest Profit

Profit is calculated as:

```text
Profit = Revenue - Budget
```

```bash
awk -F',' 'NR > 1 {
    profit = $5 - $4
    printf "%.0f,%s\n", profit, $6
}' movies_clean.csv |
sort -t',' -k1,1nr |
head -10
```

**Result:**

```text
2544505847,Avatar
1868178225,Star Wars: The Force Awakens
1645034188,Titanic
1363528810,Jurassic World
1316249360,Furious 7
1299557910,The Avengers
1202817822,Harry Potter and the Deathly Hallows: Part 2
1125035767,Avengers: Age of Ultron
1124219009,Frozen
1084279658,The Net
```

---

## Task 6 — Director with the Most Movies and Actor Appearing in the Most Movies

### Director

The `director` column may contain multiple directors separated by `|`.

```bash
awk -F',' 'NR > 1 && $9 != "" {
    n = split($9, director, "|")

    for (i = 1; i <= n; i++) {
        gsub(/"/, "", director[i])
        print director[i]
    }
}' movies_clean.csv |
sort |
uniq -c |
sort -nr |
head
```

**Top directors:**

```text
46 Woody Allen
34 Clint Eastwood
30 Steven Spielberg
30 Martin Scorsese
23 Steven Soderbergh
23 Ridley Scott
22 Ron Howard
21 Joel Schumacher
20 Brian De Palma
19 Wes Craven
```

**Woody Allen** directed the highest number of movies, with **46 movies**.

### Actor

The `cast` column may contain multiple actors separated by `|`.

```bash
awk -F',' 'NR > 1 && $7 != "" {
    n = split($7, actor, "|")

    for (i = 1; i <= n; i++) {
        gsub(/"/, "", actor[i])
        print actor[i]
    }
}' movies_clean.csv |
sort |
uniq -c |
sort -nr |
head
```

**Top actors:**

```text
72 Robert De Niro
71 Samuel L. Jackson
62 Bruce Willis
61 Nicolas Cage
53 Michael Caine
51 Robin Williams
50 John Cusack
49 Morgan Freeman
49 John Goodman
48 Susan Sarandon
```

**Robert De Niro** appears in the highest number of movies, with **72 movies**.

---

## Task 7 — Count Movies by Genre

The `genres` column may contain multiple genres separated by `|`.

```bash
awk -F',' 'NR > 1 && $14 != "" {
    n = split($14, genre, "|")

    for (i = 1; i <= n; i++) {
        gsub(/"/, "", genre[i])
        print genre[i]
    }
}' movies_clean.csv |
sort |
uniq -c |
sort -nr
```

**Result:**

```text
4760 Drama
3793 Comedy
2907 Thriller
2384 Action
1712 Romance
1637 Horror
1471 Adventure
1354 Crime
1231 Family
1229 Science Fiction
916 Fantasy
810 Mystery
699 Animation
520 Documentary
408 Music
334 History
270 War
188 Foreign
167 TV Movie
165 Western
```

`Drama` is the most common genre in the dataset, with **4,760 movies**.

---

## Task 8 — Additional Analysis Ideas

The dataset could also be used for additional analysis such as:

* Number of movies released each year
* Average movie rating/revenue by genre
* Directors with the highest average movie rating
* Actors whose movies generated the highest total revenue
* Movies with the highest return on investment (ROI)
* Number of movies with missing or zero budget/revenue values

These analyses could provide additional insights into movie trends, profitability, popularity, and data quality.

---

# Project Script

The full workflow from data cleaning through Tasks 1–7 can also be executed using:

```bash
chmod +x script.sh
./script.sh
```

The script automatically:

* cleans the raw CSV data
* removes duplicate IDs
* runs Tasks 1–7
* creates the required output CSV files
* generates `report.txt`
* removes temporary preprocessing files

---

# Directory Cleanup

Temporary preprocessing files are removed automatically after `script.sh` finishes:

```text
movies_no_newline.csv
movies_no_duplicate.csv
movies_clean.csv
```

The remaining project files are:

```text
tmdb-movies.csv
movies_sorted_by_date.csv
movies_rating_over_7.5.csv
report.txt
script.sh
README.md
```
