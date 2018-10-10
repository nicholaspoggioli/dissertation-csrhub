### Heatmap of unstandardized net KLD scores
# See https://www.r-graph-gallery.com/215-the-heatmap-function/
file <- ('C:/Dropbox/papers/active/dissertation-csrhub/project/figures/kld-sic2-sum-strengths-concerns.csv')

d1 <- as.matrix(read.csv(file, header=TRUE, row.names=1))
d1 <- t(d1)

# Heatmap with values scaled by number of observations in sic2 industry
heatmap(d1, Colv=NA, Rowv=NA, scale='column')
heatmap(d1, Colv=NA, Rowv=NA, scale='column', col = terrain.colors(256))

# Heatmap with a color key legend (https://sebastianraschka.com/Articles/heatmaps_in_r.html)
if (!require("gplots")) {
  install.packages("gplots", dependencies = TRUE)
  library(gplots)
}

heatmap.2(d1, Rowv='NA', Colv='NA', scale='column',
          density.info='none',
          trace='none',
          col=terrain.colors(256),
          dendrogram='none',
          margins=c(4,10))


### Heatmap of standardized net KLD scores
file <- ('C:/Dropbox/papers/active/dissertation-csrhub/project/figures/kld-sic2-sum-strengths-concerns-standardized.csv')

d2 <- as.matrix(read.csv(file, header=TRUE, row.names=1))
d2 <- t(d2)

# Heatmap with values scaled by industry
heatmap(d2, Colv=NA, Rowv=NA, scale='column')

# Heatmap with a color key legend (https://sebastianraschka.com/Articles/heatmaps_in_r.html)
if (!require("gplots")) {
  install.packages("gplots", dependencies = TRUE)
  library(gplots)
}

heatmap.2(d2, Rowv='NA', Colv='NA',
          density.info='none',
          trace='none',
          col=terrain.colors(256),
          dendrogram='none',
          margins=c(4,10))
