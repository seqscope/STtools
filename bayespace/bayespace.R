#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
for(i in 1:10) { #-- Create objects  'r.1', 'r.2', ... 'r.6' --
  nam <- paste0("r", i)
  assign(nam, args[i])
}



runBayespace=function(DGEdir,spatial,outpath,seed=1234,n.PCs=10,n.HVGs=2000,log.normalize=FALSE,enhanced.res=TRUE,q=4,nrep=100000)
{
   packages = c("Seurat","Matrix","SingleCellExperiment","Matrix")
    ## add more packages to load if needed
    ## Now load or install&load all
   package.check <- lapply(
      packages,
      FUN = function(x) {
        if (!require(x, character.only = TRUE)) {
          install.packages(x, repos="https://cran.rstudio.com", dependencies = TRUE)
          library(x, character.only = TRUE)
        }
      }
   )
#   if (!requireNamespace("BiocManager", quietly = TRUE))
 #     install.packages("BiocManager")

                                        # BiocManager::install("BayesSpace")
   if (!requireNamespace("devtools", quietly = TRUE))
       install.packages("devtools")

   devtools::install_github("edward130603/BayesSpace")
   library(BayesSpace)
   
   if (!dir.exists(DGEdir)){
       stop("Digital Expression Matrix path does not exist")
    }

  if(!file.exists(spatial))
  {
    stop('Spatial coordinates does not exist')
  }
  setwd(DGEdir)
  bc = read.table("barcodes.tsv",header=F)$V1
  features = read.table('features.tsv',header=F)$V2
  m = readMM('matrix.mtx')
  if(any(c(length(features),length(bc)) != dim(m)))
  {
    stop('Dimension of matrix.mtx does not match with features or barcodes')
  }
  rownames(m) = features
  colnames(m) = bc
 # m = m[,colSums(m)<=100&colSums(m)>0]  #remove outliers
  dim(m)
  miseq_pos = read.table(spatial)
  #head(miseq_pos)
  colnames(miseq_pos) = c('HDMI','lane_miseq','tile_miseq','x_miseq','y_miseq')
  sce = SingleCellExperiment(assays=list(counts=as(m, "dgCMatrix")),
                            rowData=miseq_pos$x_miseq,
                            colData=miseq_pos$y_miseq)

#sce = readVisium("VISIUMpath")
  sce = spatialPreprocess(sce, platform="ST", 
                              n.PCs=n.PCs, n.HVGs=n.HVGs, log.normalize=log.normalize)
  setwd(outpath)
  set.seed(seed)

  if (enhanced.res)
  {
    
   sce = spatialEnhance(sce, q=q, platform="ST", d=7,
                                      model="t", gamma=2,
                                      jitter_prior=0.3, jitter_scale=3.5,
                                      nrep=nrep, burn.in=100,
                                      save.chain=TRUE)
   df_enhanced=colData(sce)
   write.csv(df_enhanced,'bayespace_enhanced.csv')
   png('bayespace_cluster_enhanced.png',width=7,height=6,res=300)
   clusterPlot(sce)
   dev.off()
  }
  else
  {
    sce = spatialCluster(sce, q=q, platform="ST", d=7,
                             init.method="mclust", model="t", gamma=2,
                             nrep=nrep, burn.in=100,
                             save.chain=TRUE)
    df=colData(sce)
    write.csv(df,'bayespace.csv')
    png('bayespace_cluster.png',width=7,height=6,res=300)
    clusterPlot(sce)
    dev.off()

  }
  print("Done")
  }

runBayespace(DGEdir=r1,spatial=r2,outpath=r3,seed=as.numeric(r4),n.PCs=as.numeric(r5),n.HVGs=as.numeric(r6),log.normalize=r7,enhanced.res=r8,q=as.numeric(r9),nrep=as.numeric(r10))

# setwd(DGEdir)

# #read files
# print("Read files")
# bc = read.table("barcodes.tsv",header=F)$V1
# features = read.table('features.tsv',header=F)$V2
# m = readMM('matrix.mtx')
# if(any(c(length(features),length(bc)) != dim(m)))
# {
#   stop('Dimension of matrix.mtx does not match with features or barcodes')
# }
# rownames(m) = features
# colnames(m) = bc
# #m = m[,colSums(m)<=100&colSums(m)>0]  #remove outliers
# setwd(DGEdir)
# #read files
# print("Read files")
# bc = read.table("barcodes.tsv",header=F)$V1
# features = read.table('features.tsv',header=F)$V2
# m = readMM('matrix.mtx')


# #get spatial info
# miseq_pos = read.table(spatial)
# #head(miseq_pos)
# colnames(miseq_pos) = c('HDMI','lane_miseq','tile_miseq','x_miseq','y_miseq')
# dim(m)
# #get spatial info
# miseq_pos = read.table(spatial)
# #head(miseq_pos)
# colnames(miseq_pos) = c('HDMI','lane_miseq','tile_miseq','x_miseq','y_miseq') #may need to change the columns format






