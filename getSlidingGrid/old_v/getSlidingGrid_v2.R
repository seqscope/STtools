#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
for(i in 1:11) { #-- Create objects  'r.1', 'r.2', ... 'r.6' --
  nam <- paste0("r", i)
  assign(nam, args[i])
}

print(args[11])
####################################################################################################3
#' This function merges a list of Seurat object
#' @param seurat_object_list a list of Seurat object
mergeSeuratObj=function(seurat_object_list)
{

  for (i in names(seurat_object_list))
  {
    seurat_object_list[[i]] = RenameCells(seurat_object_list[[i]],
                                          add.cell.id = i)
  }
  merged_combined = suppressWarnings(expr=reduce(seurat_object_list,
                           merge,
                           do.normalize = FALSE))
  return(merged_combined)
}

####################################################################################################3
#' This function generate simple square grids of subfield data with user-defined binning size and collapsed HDMIs within each grid
#' @param tile_df_sub dataframe of subfied data
#' @param binx binning size of x axis
#' @param biny binning size of y axis
#' @param window sliding window size
#' @param j integer of horizontal sliding step
#' @param t interger of vertical sliding step
#' @param obj seurat object
#' @param m_tile sparse matrix, maybe made global variable?
#' @param m_bc barcodes of m_tile
#' @param m_gene barcodes of m_gene
#' @param tile integer of one tile
simpleGrid = function(tile_df_sub,binx,biny,window,j,t,obj,m_tile,m_bc,m_gene,tile,groupid)
{
  miny = min(tile_df_sub$y_miseq)
  maxy = max(tile_df_sub$y_miseq)
  minx = min(tile_df_sub$x_miseq)
  maxx = max(tile_df_sub$x_miseq)
  tile_df_sub_down = tile_df_sub[tile_df_sub$x_miseq>=(minx+window*j)&tile_df_sub$x_miseq<=(maxx-window*j),]
  miny = min(tile_df_sub_down$y_miseq)
  maxy = max(tile_df_sub_down$y_miseq)
  minx = min(tile_df_sub_down$x_miseq)
  maxx = max(tile_df_sub_down$x_miseq)
  tile_df_sub_wind = tile_df_sub_down[tile_df_sub_down$y_miseq>=(miny+window*t) & tile_df_sub_down$y_miseq<=(maxy-window*t),]
  xlim2 = c(min(tile_df_sub_wind$x_miseq),max(tile_df_sub_wind$x_miseq))
  ylim2 = c(min(tile_df_sub_wind$y_miseq),max(tile_df_sub_wind$y_miseq))


  grd = make.grid(tile_df_sub_wind$x_miseq,tile_df_sub_wind$y_miseq,tile_df_sub_wind$UMI, binx,biny, xlim2, ylim2)

  grd=t(grd)


  fn1=paste0('Temp_CollapsedHDMIsIndLength','.csv')
  fn2=paste0('Temp_CollapsedHDMIsInd','.txt')
  if (file.exists(fn1)) {
    #Delete file if it exists
    file.remove(fn1)
  }

  if (file.exists(fn2)) {
    #Delete file if it exists
    file.remove(fn2)
  }
  grd_re = make.grid(tile_df_sub_wind$x_miseq,tile_df_sub_wind$y_miseq,tile_df_sub_wind$tileHDMIind, binx, biny, xlim2, ylim2,function(x) {write(length(x), file=fn1,append = T)})
  grd_re = make.grid(tile_df_sub_wind$x_miseq,tile_df_sub_wind$y_miseq,tile_df_sub_wind$tileHDMIind, binx, biny, xlim2, ylim2,function(x) {cat(x,file=fn2,append=TRUE,sep='\n')})
  #draw the grids centers:
  # write.csv(as.numeric(colnames(grd)),paste0('grd_col',j,t,'.csv'))
  #  write.csv(as.numeric(rownames(grd)),paste0('grd_row',j,t,'.csv'))

  collapseLen = read.csv(fn1,header=F)
  collapseInd = read.table(fn2,header=F)


  collapseLen = cbind(collapseLen,cumsum(collapseLen$V1))
  colnames(collapseLen) =c("len","end")
  interv = c(0,collapseLen$end)

  #create dataframe of the assignment of collapsed grids for each HDMI

  df=data.frame('HDMIind' = collapseInd$V1,"HDMI" = m_bc[collapseInd$V1])
  assign=c()
  out=sapply(1:(dim(collapseLen)[1]),function(x) {nrep=collapseLen$len[x];return(c(assign,rep(paste0('Collapse2_',x),nrep)))})
  assign = unlist(out)
  df$assign = assign
  #fn3=paste0('HDMI_collapsing_assignment','_',j,'_',t,'.csv')
  #write.csv(df,fn3)
  #print('collapse')
  #sourceCpp(collapsePath) put this in the main function
  tic();collapseM = collapse(m_tile,collapseInd$V1,interv);toc()
  #print('finished collapse!')
  rownames(collapseM) = m_gene
  colnames(collapseM) = paste0("Collase_tile_",tile,"_sub_",groupid,"_",j,"_",t,1:(length(interv)-1))
  sparse.gbm <- Matrix(collapseM , sparse = T )


  grd=t(grd)
  pos = which(!is.na(grd), TRUE)
  pos_coor = t(sapply(1:(dim(pos)[1]),function(x) {c(as.numeric(rownames(grd)[as.numeric(pos[x,1])]),as.numeric(colnames(grd)[as.numeric(pos[x,2])]) )})) #here the grd is transposed
  colnames(pos_coor) =c("X","Y")
  coord.df = data.frame("Y"=pos_coor[,2], "X"=pos_coor[,1],"tile"=tile, stringsAsFactors=FALSE)
  #fn7=paste0('tile2112_coor_df_',j,'_',t,'.csv')
  #write.csv(coord.df,fn7)

  dge1 = collapseM
  spatial1 = coord.df
  obj1 = suppressWarnings(expr=CreateSeuratObject(counts=dge1,assay='Spatial'))
  #obj1$status = "Original"
  obj1@meta.data$tile = spatial1$tile
  obj1@meta.data$X = spatial1$X
  obj1@meta.data$Y = spatial1$Y
  obj1@meta.data$interationi=j
  obj1@meta.data$interationj=t
  #print(obj1)

  if(j==0 & t==0)
  {
    obj=obj1
  }
  else
  {
    obj = merge(obj,obj1)

  }
  return(obj)
}


####################################################################################################3
#' This function generate grids in subfields of a tile
#' @param groupid an integer indicates the id for the subfield
#' @param tile_df dataframe with spatial info of a certain tile
#' @param m_tile sparise matrix
#' @param slidestarts  a vector of the sliding steps
#' @param window sliding window size
#' @param binx x side size of the simple grid
#' @param biny y side size of the simple grid
#' @param tile integer of the tile number
getSubGrids = function(groupid,tile_df,m_tile,slidestarts,window,binx,biny,tile)

{


  #print(groupid)
  obj=suppressWarnings(CreateSeuratObject(m_tile[,1:10]))#initialize
  tile_df_sub= tile_df[tile_df$ID==groupid,]
  #sourceCpp(slidingPath) put into the main function
  obj=slidingWindow(slidestarts,tile_df_sub,window,binx,biny,simpleGrid,obj,m_tile,colnames(m_tile),rownames(m_tile),tile,groupid)
  return(obj)

}

getGroupGrids=function(i,tiles,tile_df,m_tile,slidestarts,window,binx,biny)
{
  tile=tiles[i]
  tile_df_exact=tile_df[tile_df$tile_miseq == tile,]
  nsub_x=nsub_y=5
  tile_df_exact$xcut = cut(tile_df_exact$x_miseq,nsub_x)
  tile_df_exact$ycut = cut(tile_df_exact$y_miseq,nsub_y)
  tile_df_exact=tile_df_exact%>%mutate(ID = group_indices(., xcut, ycut))

  group = unique(tile_df_exact$ID)
  group = group[order(group)]
  obj = suppressWarnings(CreateSeuratObject(m_tile[,1:10]))
  out=sapply(1:5,getSubGrids,tile_df=tile_df_exact,m_tile=m_tile,slidestarts=slidestarts,window=window,binx=binx,biny=biny,tile=tile)  #function applies on subfied
  #obj_tile = mergeSeuratObj(out)
  #obj_list[[as.character(tile)]] = obj_tile
  # return(obj_list)
}

####################################################################################################3
#' This function grids the data with user-defined binning size and collapsed HDMIs within each grid
#' @param seqscope1st Data flatform, please use "MiSeq" for now
#' @param DGEdir folder that stores barcodes.tsv, features.tsv and matrix.mtx
#' @param spatial txt file stores spatial informaiton with four columns: 'HDMI','tile_miseq','x_miseq','y_miseq'
#' @param nrow an integer of how many rows to organize the tile
#' @param ncol an integer of how many cols to organize the tile
#' @param sidesize side size of the square grid 300 represents 10um
#' @param outpath path to store the output, you need to make sure the path exists before running the function
#' @param window size of sliding window
#' @param collapsePath path of collapse.cpp
#' @param slidingPath path of slidingWindow.cpp
#' @param tile tile number. ONLY one tile number is allowed in current version. We are currently working on the scalability.
#' @export
getSlidingGrid = function(seqscope1st,DGEdir,spatial,nrow,ncol,sidesize,outpath,window,collapsePath,slidingPath,tile)
{
  options(warn=-1)
  if(missing(seqscope1st))
  {
    seqscope1st="MiSeq"
  }
  if(missing(sidesize))
  {
    sidesize=300
  }

  if (!dir.exists(DGEdir)){
    stop("DGEdir does not exist")
  }
  if (!dir.exists(outpath)){
    stop("outpath does not exist")
  }

  biny = binx = sidesize
  slidestarts = seq(0,(binx/window-1),1)

  setwd(DGEdir)
  #libraries
  packages = c("Rcpp","Matrix", "tictoc", "ggplot2", "ggsci","Seurat","rlist","cowplot","dplyr","mapplots","tictoc","purrr")
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

  sourceCpp(slidingPath)
  sourceCpp(collapsePath)
  #read files
  print("Read files")
  bc = read.table("barcodes.tsv",header=F)$V1
  features = read.table('features.tsv',header=F)$V2
  m = readMM('matrix.mtx')
  if(any(c(length(features),length(bc)) != dim(m)))
  {
    stop('Dimension of matrix.mtx does not match with features or barcodes')
  }

  rownames(m) = features
  colnames(m) = bc
  m = m[,colSums(m)<=100&colSums(m)>0]  #remove outliers
  dim(m)
  #get spatial info
  miseq_pos = read.table(spatial)
  colnames(miseq_pos) = c('HDMI','lane_miseq','tile_miseq','x_miseq','y_miseq')
  if (tile%in%miseq_pos$tile_miseq)
  {
      miseq_pos=miseq_pos[miseq_pos$tile_miseq == tile,]
  }
  else
    {
        break
    }
  # if (seqscope1st=='MiSeq')
  # {
  #   #bottom = miseq_pos[miseq_pos$tile>2100,]
  #   plotwidth = plotheight=3.5
  # }
  # else
  # {
  #   #bottom = miseq_pos
  #   plotheight=3.5
  #   plotwidth=plotheight*3
  # }

  df = data.frame("HDMI" =colnames(m),"HDMIind" = 1:(dim(m)[2]))
 # df$UMI = colSums(m_tile)
  #df$tileHDMIind= match(df$HDMI,colnames(m_tile))

  setwd(outpath)
  tile_df = merge(miseq_pos,df,by = "HDMI")  #this takes some time, just save this
  m_tile = m[,tile_df$HDMIind]
  #tile_df_file = paste0(tile_df')
  tile_df$UMI=colSums(m_tile)
  tile_df$tileHDMIind= match(df$HDMI,colnames(m_tile))
  df = data.frame("HDMI" =colnames(m),"HDMIind" = 1:(dim(m)[2]))
  df$UMI = colSums(m_tile)
  df$tileHDMIind= match(df$HDMI,colnames(m_tile))

  #setwd(outpath)
  #tile_df = merge(bottom,df,by = "HDMI")  #this takes some time, just save this
  #tile_df_file = paste0(tile_df')
  #tile_df$aggrInd =  as.numeric(factor(tile_df$tile_miseq))-1

  #m_tile = m[,tile_df$HDMIind]

  #use parralel computing in the linux, on different tiles
  obj_list = list()
  tile_df_exact=tile_df[tile_df$tile_miseq == tile,]
  # if(is.null(dim(tile_df)))
  #    return ()
  nsub_x=nsub_y=5
  tile_df_exact$xcut = cut(tile_df_exact$x_miseq,nsub_x)
  tile_df_exact$ycut = cut(tile_df_exact$y_miseq,nsub_y)
  tile_df_exact=tile_df_exact %>% mutate(ID = group_indices(., xcut, ycut))
  group = unique(tile_df_exact$ID)
  group = group[order(group)]
  obj = suppressWarnings(CreateSeuratObject(m_tile[,1:10]))
  print('collapsing')
  print(group)
  out=sapply(group[1:5],getSubGrids,tile_df=tile_df_exact,m_tile=m_tile,slidestarts=slidestarts,window=window,binx=binx,biny=biny,tile=tile)  #function applies on subfied
  print('finish collapsing')
  obj_tile = mergeSeuratObj(out)
  obj_list[[as.character(tile)]] = obj_tile
  obj= mergeSeuratObj(obj_list)


  toc()
#for super tile
  tile_df = obj@meta.data
  addson_hori = max(tile_df$Y)
  addson_verti = max(tile_df$X)
  tile_df$aggrInd =  as.numeric(factor(tile_df$tile))-1
  tile_df$aggrInd2 = 0
  tile_df[tile_df$aggrInd<ncol,"aggrInd2"] = tile_df[tile_df$aggrInd<ncol,]$aggrInd+ncol
  tile_df[tile_df$aggrInd>=ncol,"aggrInd2"] = tile_df[tile_df$aggrInd>=ncol,]$aggrInd-ncol
  tile_df$y_miseq_expand = tile_df$Y +  addson_hori*(((tile_df$aggrInd2%%ncol)))
  tile_df$x_miseq_expand =   tile_df$X +  addson_verti*(floor((tile_df$aggrInd2/ncol)))
  obj@meta.data$X_expand = tile_df$x_miseq_expand
  obj@meta.data$Y_expand = tile_df$y_miseq_expand

  obj@images$image = new(
      Class = 'SlideSeq',
      assay = "Spatial",
      key = "image_",
      coordinates = obj@meta.data[,c('Y_expand','X_expand')]
    )
  
  objfile=paste0('SquareGrids_tile_',tile,'sliding.RDS')
  if (file.exists(objfile))
    file.remove(objfile)
  saveRDS(obj,objfile)
  print('Done!')
}




print(r1)
print(r5)
getSlidingGrid(r1,r2,r3,as.numeric(r4),as.numeric(r5),as.numeric(r6),r7,as.numeric(r8),r9,r10,as.numeric(r11))

