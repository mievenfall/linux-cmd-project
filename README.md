## Data Cleaning / Data Pre-processing


#### Anomaly from CSV file: 
#### 	1. There are fields with comma (,) inside double quotation marks ("...") thus results in columns shift after using awk -F','
####	2. Some overview got new line which affects the number of lines
####	3. Need to check if any duplicates


#### Removing new lines from overview then remove duplicates
```
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
This code reduce the total line from 10880 to 10867.

```
awk -F',' 'NR == 1 || !seen[$1]++' movies_no_newline.csv > movies_no_duplicate.csv
```
The csv file after removing duplicates now have 10866 lines.

```
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
Dataset ready to use after removing all comma (,) inside quotation marks "..." for less confusion



## Data Processing / Tasks

### Task 1 - Sort films by release datas in descendant order -> save new file
```
awk -F',' 'NR > 1  {
	split($16,date,"/")
	printf "%04d%02d%02d,%s\n", $19, date[1], date[2], $0
}' movies_clean.csv | sort -t',' -k1,1nr | cut -d',' -f2- > movies_sorted_by_date.csv
```
Newest release: Martyrs (released 12/31/15)
Oldest release: The Unforgiven (released 1/1/60)


### Task 2 - Filter films with vote_average > 7.5 -> save new file
```
awk -F',' 'NR==1 || $18 > 7.5' movies_clean.csv > movies_rating_over_7.5.csv
```
Total of 350 films with average rating above 7.5


### Task 3 - Films with highest and lowest revenue
```
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
Film with highest revenue:
Movie: Avatar
Revenue: 2781505847


```
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
This one results in a revenue of 0 -> could be missing or unknown data, and also might appear many places in the dataset -> let's find lowest revenue besides the 0

```
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
Movie: Shattered Glass
Revenue: 2

Check if there is any other movie with revenue = 2
```
awk -F',' 'NR > 1 && $5 == 2 {
	print "Movie:", $6
}' movies_clean.csv
```
Film with lowest revenue:
Movie: Shattered Glass
Movie: Mallrats
Revenue: 2


### Task 4 - Total revenue of all films
```
awk -F',' '
NR > 1 {
	total += $5
}
END {
	printf "Total Revenue: %.0f\n", total
}' movies_clean.csv
```
Total Revenue: 432719225875
(or 432,719,225,875)


### Task 5 - Top 10 films with highest profit
```
awk -F',' 'NR > 1 {
	profit = $5 - $4
	print profit "," $6
}' movies_clean.csv | sort -t',' -k1,1nr | head -10n
```
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


### Task 6 - Director having the most number of films and actor having the most number of films

```
awk -F',' 'NR > 1 && $9 != "" {
	n = split($9, director, "|")
	
	for (i = 1; i <= n; i++) { 
		gsub(/"/, "", director[i]) 
                print director[i]
        }
}' movies_clean.csv | sort | uniq -c | sort -nr | head
```
}
Director:
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
awk -F',' 'NR > 1 && $7 != "" {
	n = split($7, actor, "|")
	
	for (i = 1; i <= n; i++) { 
		gsub(/"/, "", actor[i]) 
                print actor[i]
        }
}' movies_clean.csv | sort | uniq -c | sort -nr | head
```
Actor:
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


### Task 7 - Compile films by genres
```
awk -F',' 'NR > 1 && $14 != "" {
	n = split($14, genre, "|")
	
	for (i = 1; i <= n; i++) { 
		gsub(/"/, "", genre[i]) 
                print genre[i]
        }
}' movies_clean.csv | sort | uniq -c | sort -nr | head
```
Genre:
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


## Directory clean up
#### Removing temporary files for processing only; leaving the 2 required files
```
rm movies_no_newline.csv movies_no_duplicate.csv movies_clean.csv
```

