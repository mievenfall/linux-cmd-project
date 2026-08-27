#!/bin/bash

# Linux CMD Movie Dataset Project
# Input: tmdb-movies.csv
# Output:
#   - movies_sorted_by_date.csv
#   - movies_rating_over_7.5.csv
#   - report.txt

INPUT="tmdb-movies.csv"
NO_NEWLINE="movies_no_newline.csv"
NO_DUPLICATE="movies_no_duplicate.csv"
CLEAN="movies_clean.csv"
SORTED="movies_sorted_by_date.csv"
RATING="movies_rating_over_7.5.csv"
REPORT="report.txt"

if [ ! -f "$INPUT" ]; then
    echo "Error: $INPUT not found."
    exit 1
fi

echo "Running data cleaning and analysis..."

# ---------------------------
# DATA CLEANING
# ---------------------------

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
' "$INPUT" > "$NO_NEWLINE"

awk -F',' 'NR == 1 || !seen[$1]++' "$NO_NEWLINE" > "$NO_DUPLICATE"

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
' "$NO_DUPLICATE" > "$CLEAN"

{
    echo "TMDB MOVIE DATASET ANALYSIS REPORT"
    echo "=================================="
    echo
    echo "Generated from: $INPUT"
    echo
} > "$REPORT"

# ---------------------------
# TASK 1
# ---------------------------

{
    head -n 1 "$CLEAN"

    awk -F',' 'NR > 1 {
        split($16, date, "/")
        printf "%04d%02d%02d,%s\n", $19, date[1], date[2], $0
    }' "$CLEAN" |
    sort -t',' -k1,1nr |
    cut -d',' -f2-
} > "$SORTED"

{
    echo "TASK 1 - MOVIES SORTED BY RELEASE DATE"
    echo "---------------------------------------"

    awk -F',' 'NR == 2 {
        print "Newest release:"
        print "Movie: " $6
        print "Release date: " $16
    }' "$SORTED"

    tail -n 1 "$SORTED" |
    awk -F',' '{
        print "Oldest release:"
        print "Movie: " $6
        print "Release date: " $16
    }'

    echo "Output file: $SORTED"
    echo
} >> "$REPORT"

# ---------------------------
# TASK 2
# ---------------------------

awk -F',' 'NR == 1 || $18 > 7.5' "$CLEAN" > "$RATING"

{
    echo "TASK 2 - MOVIES WITH AVERAGE RATING ABOVE 7.5"
    echo "-----------------------------------------------"

    awk -F',' 'NR > 1 && $18 > 7.5 {count++}
    END {print "Total movies: " count}' "$CLEAN"

    echo "Output file: $RATING"
    echo
} >> "$REPORT"

# ---------------------------
# TASK 3
# ---------------------------

{
    echo "TASK 3 - HIGHEST AND LOWEST REVENUE"
    echo "------------------------------------"

    awk -F',' '
    NR > 1 {
        if (max == "" || $5 > max) {
            max = $5
            max_movie = $6
        }
    }
    END {
        print "Highest revenue:"
        print "Movie: " max_movie
        printf "Revenue: %.0f\n", max
    }' "$CLEAN"

    echo

    min_revenue=$(awk -F',' '
    NR > 1 && $5 > 0 {
        if (min == "" || $5 < min)
            min = $5
    }
    END {printf "%.0f\n", min}' "$CLEAN")

    echo "Lowest non-zero revenue: $min_revenue"
    echo "Movie(s):"

    awk -F',' -v min="$min_revenue" '
    NR > 1 && $5 == min {
        print "- " $6
    }' "$CLEAN"

    echo
} >> "$REPORT"

# ---------------------------
# TASK 4
# ---------------------------

{
    echo "TASK 4 - TOTAL REVENUE"
    echo "----------------------"

    awk -F',' '
    NR > 1 {
        total += $5
    }
    END {
        printf "Total Revenue: %.0f\n", total
    }' "$CLEAN"

    echo
} >> "$REPORT"

# ---------------------------
# TASK 5
# ---------------------------

{
    echo "TASK 5 - TOP 10 MOVIES WITH HIGHEST PROFIT"
    echo "-------------------------------------------"
    printf "%-15s %s\n" "Profit" "Movie"

    awk -F',' 'NR > 1 {
        profit = $5 - $4
        printf "%.0f,%s\n", profit, $6
    }' "$CLEAN" |
    sort -t',' -k1,1nr |
    head -10 |
    awk -F',' '{
        printf "%-15s %s\n", $1, $2
    }'

    echo
} >> "$REPORT"

# ---------------------------
# TASK 6
# ---------------------------

{
    echo "TASK 6 - DIRECTORS AND ACTORS WITH THE MOST MOVIES"
    echo "---------------------------------------------------"
    echo "Top 10 directors:"

    awk -F',' 'NR > 1 && $9 != "" {
        n = split($9, director, "|")

        for (i = 1; i <= n; i++) {
            gsub(/"/, "", director[i])
            print director[i]
        }
    }' "$CLEAN" |
    sort |
    uniq -c |
    sort -nr |
    head

    echo
    echo "Top 10 actors:"

    awk -F',' 'NR > 1 && $7 != "" {
        n = split($7, actor, "|")

        for (i = 1; i <= n; i++) {
            gsub(/"/, "", actor[i])
            print actor[i]
        }
    }' "$CLEAN" |
    sort |
    uniq -c |
    sort -nr |
    head

    echo
} >> "$REPORT"

# ---------------------------
# TASK 7
# ---------------------------

{
    echo "TASK 7 - NUMBER OF MOVIES BY GENRE"
    echo "----------------------------------"

    awk -F',' 'NR > 1 && $14 != "" {
        n = split($14, genre, "|")

        for (i = 1; i <= n; i++) {
            gsub(/"/, "", genre[i])
            print genre[i]
        }
    }' "$CLEAN" |
    sort |
    uniq -c |
    sort -nr

    echo
} >> "$REPORT"

# ---------------------------
# CLEAN UP TEMP FILES
# ---------------------------

rm -f "$NO_NEWLINE" "$NO_DUPLICATE" "$CLEAN"

echo "Done."
echo "Created:"
echo "  $SORTED"
echo "  $RATING"
echo "  $REPORT"

