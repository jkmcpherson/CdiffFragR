

getwd()
options(warn=-1)

getwd()

source("R/Functions.21.12.07.R")
unzip("data/F-Ribotyping_Reps.lite.15.zip")# will move current directory

rox.ladder <- c(50,  75, 100, 125, 150, 200, 250, 300, 350, 400, 450, 475, 500,
                550, 600, 650, 700, 750, 800, 850, 900, 950, 1000)

# Restore the object
cd.db <- readRDS(file = "Cdiff_DB_lite.15.RDS")

p1 <- list.files("Files_to_analyze/",
                 recursive = T, full.names = T, pattern = ".fsa")
p1 <- gsub("//", "/", p1)

fsa.pick <- sapply(lapply(strsplit(p1, split = "[.]"), rev), "[[", 1)
p1 <- p1[fsa.pick == "fsa" ] # only use files with .fsa file extension

ids <-strsplit(p1, split = "[/]")
ids <- sapply(ids, "[[", 2)

jpegs <- gsub("fsa", "jpeg", ids)

results.dir <- paste("Results", Sys.time())
results.dir <- gsub(" |[:]", "_", results.dir)
dir.create(results.dir)

dir.create("Files_analyzed")

results <-  as.data.frame(matrix(ncol = 7, nrow = length(p1)))
colnames(results) <- c("query_file", "Confidence",
                       "Hit_1",  "ribo_1",  "Dist_1",
                       "hit_1_jpeg", "chormatogram_jpeg")


querys.db <- list()


# the most common arguements used to build the database are used to find the match

for(i in 1 : nrow(results)){

  print(i)

  sum.fsa(p1[i])
  
  i.res <- find.match(file.query = p1[i], ladder = rox.ladder, database = cd.db)

  if(i.res[1] !=  "no match found"){

    hit.file <- paste0(results.dir, "/hit_",  jpegs[i])

    jpeg(    hit.file)

    res1 <- compare.frags(query.file = p1[i], hit.file = names(i.res[1]))
    results$Hit_1[i] <- res1$hit.file
    results$hit_1_jpeg[i] <-     hit.file

    results$ribo_1[i] <- res1$ribotype
    results$Dist_1[i] <- res1$BCdist

    dev.off()


  }else{

    results$Hit_1[i] <- i.res[1]

  }

  chrom.file <- paste0(results.dir, "/chrom_",  jpegs[i])
  jpeg(  chrom.file, height = 800, width = 800)
  plot.fsa(file_path = p1[i], ladder = rox.ladder, cutoff = 250)
  dev.off()

  results$chormatogram_jpeg[i] <- chrom.file

  file.rename(from = p1[i], to = gsub("Files_to_analyze", "Files_analyzed", p1[i]))

}

p1_names <- gsub("Files_to_analyze/", "", p1)

results$query_file <- p1_names
results$Confidence[results$Dist_1 < 0.1] <- "good match"
results$Confidence[results$Dist_1 >=  0.1] <- "questionable match"
results$Confidence[results$Dist_1 >=  0.2] <- "poor match"

write.csv(results, paste0(results.dir, "/SUMMARY.csv"))
print("Success!")

zip(zipfile = paste0("Results", Sys.Date(), ".zip"), files = results.dir)

#iteratively build file results_collated
results_collated <- read.csv("Results_Collated.csv")
results_collated_export <- rbind(results_collated[,-1], results)
write.csv(results_collated_export, "Results_Collated.csv")
print("Results collated!")


