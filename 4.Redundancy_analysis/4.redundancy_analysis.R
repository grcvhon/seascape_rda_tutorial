# --------------------------- #
#
# Tutorial:
# Seascape Redundancy Analysis
# 
# Description:
# Perform a redundancy analysis (RDA).
#
# Data:
# European lobster SNP genotypes generated by a Fluidigm EP1 system.
# Tutorial uses 37 sites from the original study (Jenkins et al. 2019).
# https://doi.org/10.1111/eva.12849.
#
# Notes before execution:
# 1. Make sure all required R packages are installed.
# 2. Set working directory to the location of this R script.
# 3. All previous steps in this repository must be executed successfully before running this script.
#
# --------------------------- #

# Load packages
library(tidyverse)
library(psych)
library(adespatial)
library(vegan)

# Import genetic data
allele_freqs = read.csv("../1.Prepare_genetic_data/allele_freqs.csv", row.names = 1, check.names = FALSE)

# Import spatial data
dbmem.raw = read.csv("../2.Prepare_spatial_data/dbmems.csv")

# Import environmental data
env.raw = read.csv("../3.Prepare_environmental_data/environmental_data.csv", row.names = 1)

# Set seed
set.seed(123)


#--------------#
#
# Multicollinearity checks
#
#--------------#

# Plot and run correlation test on environmental variables
pairs.panels(env.raw, scale = TRUE)

# Remove correlated variables
env.data = subset(env.raw, select = -c(sst_mean, sbs_mean))
pairs.panels(env.data, scale = TRUE)


#--------------#
#
# Identify significant variables
#
#--------------#

# Use forward selection to identify significant environmental variables
env.for = forward.sel(Y = allele_freqs, X = env.data, alpha = 0.01)
env.for

# Use forward selection to identify significant dbmems
dbmem.for = forward.sel(Y = allele_freqs, X = dbmem.raw, alpha = 0.01)
dbmem.for

# Subset only significant independent variables to include in the RDA
env.sig = subset(env.data, select = env.for$variables)
str(env.sig)
dbmem.sig = subset(dbmem.raw, select = dbmem.for$variables)
str(dbmem.sig)

# Combine environmental variables and dbmems
env.dbmems = cbind(env.sig, dbmem.sig)
str(env.dbmems)


#--------------#
#
# Redundancy analysis
#
#--------------#

# Perform RDA with all variables
rda1 = rda(allele_freqs ~ ., data = env.dbmems, scale = TRUE)
rda1

# Model summaries
RsquareAdj(rda1) # adjusted Rsquared 
vif.cca(rda1) # variance inflation factor (<10 OK)
anova.cca(rda1, permutations = 1000) # full model
anova.cca(rda1, permutations = 1000, by="margin") # per variable 

# Variance explained by each canonical axis
summary(eigenvals(rda1, model = "constrained"))
screeplot(rda1)

# Create a dataframe to correctly colour regions
col_dframe = data.frame("site" = rownames(allele_freqs))

# Function to add regional labels to dataframe
addregion = function(x){
  # If pop label is present function will output the region
  if(x=="Ale"|x=="The"|x=="Tor"|x=="Sky") y = "Aegean Sea"
  if(x=="Sar"|x=="Laz") y = "Central Mediterranean"
  if(x=="Vig"|x=="Brd"|x=="Cro"|x=="Eye"|x=="Heb"|x=="Iom"|x=="Ios"|x=="Loo"|x=="Lyn"|x=="Ork"|x=="Pad"|x=="Pem"|x=="She"|x=="Sbs"|x=="Sul") y = "Atlantic"
  if(x=="Jer"|x=="Idr"|x=="Cor"|x=="Hoo"|x=="Kil"|x=="Mul"|x=="Ven") y = "Atlantic"
  if(x=="Hel"|x=="Oos"|x=="Tro"|x=="Ber"|x=="Flo"|x=="Sin"|x=="Gul"|x=="Kav"|x=="Lys") y = "Scandinavia"
  return(y)
}

# Add regional labels
col_dframe$region = sapply(col_dframe$site, addregion)

# Add factor levels
region_order = c("Scandinavia","Atlantic","Central Mediterranean", "Aegean Sea")
col_dframe$region = factor(col_dframe$region, levels = region_order)

# Create colour scheme
# blue=#377EB8, green=#7FC97F, orange=#FDB462, red=#E31A1C
cols = c("#7FC97F","#377EB8","#FDB462","#E31A1C")

# Visualise results of RDA
png("rda.png", width = 8, height = 7, units = "in", res = 600)
plot(rda1, type="n", scaling = 3)
title("Seascape redundancy analysis")
# SITES
points(rda1, display="sites", pch=21, scaling=3, cex=1.5, col="black",
       bg=cols[col_dframe$region]) # sites
# text(rda1, display="sites", scaling = 3, col="black", font=2, pos=4)
# PREDICTORS
text(rda1, display="bp", scaling=3, col="red1", cex=1, lwd=2)
# SNPS
# text(rda1, display="species", scaling = 3, col="blue", cex=0.7, pos=4) # SNPs
# LEGEND
legend("bottomleft", legend=levels(col_dframe$region), bty="n", col="black",
       pch=21, cex=1.2, pt.bg=cols)
# OTHER LABELS
adj.R2 = round(RsquareAdj(rda1)$adj.r.squared, 3)
mtext(bquote(italic("R")^"2"~"= "~.(adj.R2)), side = 3, adj = 0.5)
dev.off()


#--------------#
#
# Partial redundancy analysis
#
#--------------#

# Perform RDA while controlling for geographical location
pRDA = rda(allele_freqs ~ sbt_mean + sss_mean + ssca_mean + Condition(MEM1+MEM2+MEM3+MEM5),
           data = env.dbmems, scale = TRUE)
pRDA
RsquareAdj(pRDA) # adjusted Rsquared 
vif.cca(pRDA) # variance inflation factor (<10 OK)
anova.cca(pRDA, permutations = 1000) # full model
anova.cca(pRDA, permutations = 1000, by = "margin") # per variable

# Visualise results of RDA
png("partial_rda.png", width = 9, height = 7, units = "in", res = 600)
plot(pRDA, type="n", scaling = 3)
title("Seascape partial redundancy analysis")
# SITES
points(pRDA, display="sites", pch=21, scaling=3, cex=1.5, col="black",
       bg=cols[col_dframe$region]) # sites
text(pRDA, display="sites", scaling = 3, col="black", font=2, pos=4)
# PREDICTORS
text(pRDA, display="bp", scaling=3, col="red1", cex=1, lwd=2)
# SNPS
# text(pRDA, display="species", scaling = 3, col="blue", cex=0.7, pos=4) # SNPs
# LEGEND
legend("topleft", legend=levels(col_dframe$region), bty="n", col="black",
       pch=21, cex=1.2, pt.bg=cols)
# OTHER LABELS
adj.R2 = round(RsquareAdj(pRDA)$adj.r.squared, 3)
mtext(bquote(italic("R")^"2"~"= "~.(adj.R2)), side = 3, adj = 0.5)
dev.off()


# --------------#
#
# Candidate SNPs for local adaptation
#
# --------------#

# Which axes are significant?
anova.cca(pRDA, permutations = 1000, by = "axis")

# Extract SNP loadings for sig. axes
snp.load = scores(pRDA, choices = 1, display = "species")

# Plot histograms of SNP loadings
hist(snp.load, main = "SNP loadings on RDA1")

# Identify SNPs in the tails of the distribution
# Function from https://popgen.nescent.org/2018-03-27_RDA_GEA.html
outliers = function(x,z){
  lims = mean(x) + c(-1, 1) * z * sd(x) # find loadings +/-z sd from mean loading     
  x[x < lims[1] | x > lims[2]]          # locus names in these tails
}

# x = loadings vector, z = number of standard deviations to use
candidates = outliers(x = snp.load, z = 2.5)

# Convert matric to dataframe
snp.load.df = snp.load %>% as.data.frame
snp.load.df$SNP_ID = rownames(snp.load.df)
str(snp.load.df)

# Extract locus ID
snp.load.df %>% dplyr::filter(RDA1 %in% candidates)

# Further info on this analysis in this tutorial:
# https://popgen.nescent.org/2018-03-27_RDA_GEA.html

