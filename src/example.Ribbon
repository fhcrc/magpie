library(plyr)

## Summarize the counts for each taxon over the other variable(s) (in
## this case, sample ID).

tallies.taxa <- ddply(by.specimen, .(tax_name), summarize, total.count = sum(tally))

## Sort the results by descending total count.
tallies.taxa <- tallies.taxa[with(tallies.taxa, order(-total.count)), ]

## TODO Save the result.
## write.csv(tallies.taxa, file = ribbon.output, ...)

head(tallies.taxa, n = 5)
