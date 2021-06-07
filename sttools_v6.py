#modules
import argparse
import os, sys
import subprocess as sp

parser = argparse.ArgumentParser(description="STtools Main Launcher")
parser.add_argument("--run-all", default=False, action='store_true', help="Run all steps sequentially")
parser.add_argument("--run-steps", type=str, help="Comma-separated string containing the steps to run")
parser.add_argument("--seq1",type=str, help="Path to 1nd-Seq FASTQ.gz file")
parser.add_argument("-l","--hdmilength",type=int,default=20, help="An integer indicating the length of the HDMIs") #if not specify -l erro None occurs
parser.add_argument("-s", "--star-path", type=str, default="STAR", help="Binary folder path to STAR executable") #if not given use current directory
parser.add_argument("-q", "--seqtk-path", type=str, default="seqtk", help="Binary folder path to seqtk executable")
parser.add_argument("-g", "--genome", type=str, help="Path to the reference files")
parser.add_argument("--fq1", type=str, help="Path to 2nd-Seq Read 1 FASTQ.gz file")
parser.add_argument("--fq2", type=str, help="Path to 2nd-Seq Read 2 FASTQ.gz file")
parser.add_argument("-o","--outprefix" ,type=str, help="Prefix for STARsolo output",default='Sample')
parser.add_argument("--STtools",type=str,help='Path to the scripts of STtools scripts',default='STtools')
parser.add_argument("--py",type=str,help='Binary path to python executable')
parser.add_argument("--tiles",type=str,help='tiles')
parser.add_argument("--sidesize",type=int,help='side size of square gridssidesize',default=300)
parser.add_argument("--window",type=int,help='sliding size of sliding window',default=150)
parser.add_argument("-c", "--cores",type=int,help='number of cores',default=5)
parser.add_argument("-m", "--maxScale",type=float,help='max number for color bar of HDMI density plot')
parser.add_argument("--DGEdir",type=str,help='Directory of digital expression matrix for griding')
parser.add_argument("--subDGEdir",type=str,help='Directory of digiral expression matrix containing spliced and unspliced reads for subcellular analysis')
#parser.add_argument("--subDGE",type=str,help='Directory of digiral expression matrix containing spliced and unspliced reads for subcellular analysis')
parser.add_argument("--hdmi2ndSeq",type=str,help='Path to .txt file with HDMIs from SeqScope 2nd-Seq')
parser.add_argument("-a","--alpha",type=float,help='transparency when ploting subCelluar images')
parser.add_argument("--spatial",type=str,help='Path to .txt file of spatial coordinates. Please see readme for file format')
parser.add_argument("--whitelist",type=str,help='Path to .txt file of whitelist for alignment. Please see xxx for file format')
parser.add_argument("--nFeaturePlotOnly",type=str,help='Plot feature plot only during clustering and mapping',default='FALSE')
parser.add_argument("--geneCount1",type=float,help='cutoff of nFeature_Spatial of Seurat spatial object of simple square grids for clustering',default=0)
parser.add_argument("--geneCount2",type=float,help='cutoff of nFeature_Spatial of Seurat spatial object of sliding square grids for clustering',default=0)
parser.add_argument("--simpleGridsPath",type=str,help='path to rds file of simple squrae grids')
parser.add_argument("--slidingGridsPath",type=str,help='path to rds file of sliding squrae grids')


#Functions
def step1():

    print('Start running Step 1: extract coordinates')
    #check files
    if(os.path.isfile(args.seq1)==False):
        raise ValueError("File --seq1 does not exist")
    if(os.path.isfile(args.fq1)==False):
        raise ValueError("File --fq1 does not exist")
    if(os.path.isdir(args.STtools)==False):
        raise ValueError("Directory --STtools does not exist")
    if ( args.hdmilength is None ):
        args.hdmilength=20

    args.extract=args.STtools+"/extractCoordinates/extractCoord_v2.sh"
    cmd1 = "bash {args.extract} -m {args.seq1} -h {args.fq1} -l {args.hdmilength}".format(args=args)
    ret = os.system(cmd1)
    if ( ret != 0 ):
        raise ValueError(f"ERROR in running {cmd1}, returning exit code {ret}")


    no_miseq=sp.getoutput("wc -l ./HDMIs-MiSeq-temp.txt")
    #print(no_miseq)
    no_miseq_uniq=sp.getoutput("wc -l ./whitelist.txt")
    f=open("./summary_step1.txt","w")
    f.write('MiSeq reads:'+str(no_miseq)+" \n")
    f.write('Unique MiSeq:' +str(no_miseq_uniq) +' \n')
    f.close()    

def step3():

    print('Start running Step 2: STARsolo alignment')
    if ( args.fq1 is None ):
        raise ValueError("Cannot find --fq1 argument. Need to specify for running all")
    if ( args.fq2 is None ):
        raise ValueError("Cannot find --fq2 argument. Need to specify for running all")
    if ( args.genome is None ):
        raise ValueError("Cannot find --genome argument. Need to specify for running all")

    if(args.whitelist is None):
       args.whitelist=os.getcwd()+"/whitelist.txt"
    if(os.path.isfile(args.whitelist)==False):
         raise ValueError("Whitelist from STEP 1 output does not exist")
    #if(os.path.isfile(spatial)==False):
     #    raise ValueError("Spatial coordinates from STEP 1 output does not exist")

    if ( args.hdmilength is None ):
        args.hdmilength=20
    if(os.path.isdir(args.star_path)==False):
        raise ValueError("Directory --star-path does not exist")
    if(os.path.isdir(args.seqtk_path)==False):
        raise ValueError("Directory --seqtk-path does not exist")
    if(os.path.isdir(args.STtools)==False):
        raise ValueError("Directory --STtools does not exist")
    args.align=args.STtools+"/align/align_v2.sh"
    cmd2 = "bash {args.align} -a {args.fq1} -b {args.fq2} -l {args.hdmilength} -w {args.whitelist} -o {args.outprefix} -t {args.star_path} -q {args.seqtk_path} -g {args.genome}".format(args=args) 
    ret = os.system(cmd2)
    if ( ret != 0 ):
        raise ValueError(f"ERROR in running {cmd2}, returning exit code {ret}")


    with open(args.outprefix+'Solo.out/GeneFull/Summary.csv','r') as firstfile, open('summary_step3.txt','a') as secondfile:
        for line in firstfile:
               
             # append content to second file
             secondfile.write(line)

   # no_hiseq=sp.getoutput("wc -l ./HDMI_SeqScope_2nd.txt")
    #print(no_miseq)
  #  args.out=os.getcwd()+"/"+args.outprefix+"Solo.out/GeneFull/Summary.csv"
 #   print(args.out)
#    os.system("scp {args.out} summary_step3.txt")
    #print(out)
    #print(args.out)
    
    #starsolo=sp.getoutput('less {args.out}')
    #f=open("summary_step3.txt","w")
    #f.write('HiSeq reads:'+str(no_hiseq)+" \n")
    #f.write('StarSolo summmaries:' +' \n')
    #f.write((starsolo))
    #f.close()
    #copyfile(args.out, 'summary_step3.txt')

    ##no_hiseq=sp.getoutput("wc -l HDMI_SeqScope_2nd.txt")
   # print(no_hiseq)
   # out=os.getcwd()+"/"+args.outprefix+"Solo/GeneFull/Summary.csv"
   # print(out)
   # args.out=out
   # print(args.out)
   # starsolo=sp.getoutput('less {args.out}')
   # f=open("./summary_step3.txt","w")
   # f.write('HiSeq reads:'+str(no_hiseq)+" \n")
   # f.write('StarSolo summmaries:' +' \n')
   # f.write((starsolo))
    #f.close()

def step2():
    print("Tissue boundary estimation")
    if(args.hdmi2ndSeq is None):
        args.hdmi2ndSeq=os.getcwd()+"/HDMI_SeqScope_2nd.txt"
    
    if(args.spatial is None):
        args.spatial=os.getcwd()+"/spatialcoordinates.txt"
    if(args.maxScale is None):
        args.maxScale='0'

    if(os.path.isfile(args.spatial)==False):
        raise ValueError("Spatial coordinates from STEP 1 output does not exist")
    if(os.path.isfile(args.hdmi2ndSeq)==False):
        raise ValueError("HDMIs from 2nd-Seq from STEP 2 output does not exist")
    #args.maxScale=2
    args.outpath=os.getcwd()
    args.estTB=args.STtools+"/estimateTissueBoundary/estimateTissueBoundary.py"
    cmd3="{args.py} {args.estTB} {args.spatial} {args.hdmi2ndSeq} {args.maxScale} {args.outpath} ".format(args=args)
    ret = os.system(cmd3)
    if ( ret != 0 ):
        raise ValueError(f"ERROR in running {cmd3}, returning exit code {ret}")

   # no_hiseq=sp.getoutput("wc -l ./HDMI_SeqScope_2nd.txt")
    #print(no_miseq)
    #out={args.outpath}+"/"+"args.o"+"Solo/GeneFull/Summary.csv"
    #print(out)
    #args.out=out
    #starsolo=sp.getoutput('less {args.out}')
    #f=open("summary_step2.txt","w")
    #f.write('HiSeq reads:'+str(no_hiseq)+" \n")
    #f.write('StarSolo summmaries:' +' \n')
    #f.write((starsolo))
    #f.close()


def step4():
    print('Start Simple Gridding')
    args.nrow=1
    args.ncol=1
    args.collapsePath=args.STtools+"/getSimpleGrid/collapse.cpp"
    args.outpath=os.getcwd()
    if(args.DGEdir is None):
        args.DGEdir=os.getcwd()+'/'+args.outprefix+"Solo.out/GeneFull/raw/"
    if(os.path.isdir(args.DGEdir)==False):
        raise ValueError("Directory --DGEdir does not exist")
    if(('seqscope1st' in vars(args))==False):
        args.seqscope1st='MiSeq'
    if(os.path.isfile(args.collapsePath)==False):
        raise ValueError("File --collapsePath does not exist")
    if(args.spatial is None):
        args.spatial=os.getcwd()+"/spatialcoordinates.txt"
    args.simple=args.STtools+"/getSimpleGrid/simpleGrid_v2.R"
    cmd4="Rscript {args.simple} {args.seqscope1st} {args.DGEdir} {args.spatial} {args.tiles} {args.nrow} {args.ncol} {args.sidesize} {args.outpath} {args.collapseP\
ath}".format(args=args)
    ret = os.system(cmd4)
    if ( ret != 0 ):
        raise ValueError(f"ERROR in running {cmd4}, returning exit code {ret}")
    no_bc=sp.getoutput("wc -l collapsedBarcodes.csv")
    no_gene=sp.getoutput("wc -l collapsedGenes.csv")

    print(no_bc)
    print(args.outpath)
    fout=args.outpath+"/summary_step4.txt"
    f=open(fout,"w")
    f.write('Total number of collapsed grids:'+str(no_bc)+" \n")
    f.write('Total number of genes:' +str(no_gene) +' \n')
    f.close()

def step5():
    print("Start Sliding Window Gridding")
    args.nrow=1
    args.ncol=1
    args.collapsePath=args.STtools+"/getSimpleGrid/collapse.cpp"
    #args.slidingPath=args.STtools+"/getSlidingGrid/slidingWindow.cpp"
    args.outpath=os.getcwd()
    if(args.DGEdir is None):
        args.DGEdir=os.getcwd()+'/'+args.outprefix+"Solo.out/GeneFull/raw/"
    if(os.path.isdir(args.DGEdir)==False):
        raise ValueError("Directory --DGEdir does not exist")
    if(os.path.isfile(args.collapsePath)==False):
        raise ValueError("File --collapsePath does not exist")
    #if(os.path.isfile(args.slidingPath)==False):
     #   raise ValueError("File --slidingPath does not exist")
    if(('seqscope1st' in vars(args))==False):
        args.seqscope1st='MiSeq'
    if(args.spatial is None):
        args.spatial=os.getcwd()+"/spatialcoordinates.txt"
    if(os.path.isfile(args.spatial)==False):
        raise ValueError("File --spatial does not exist")
    if(args.cores is None):
        args.cores=5
        
    if(args.window is None):
        args.window=150
    if(args.tiles is None):
        raise ValueError("Tiles are required")
    tiles_vec =args.tiles.split(',')
   # inputF=os.getcwd()+'/inputTiles.txt'
   # with open(inputF, 'w') as f:
   #     for l in tiles_vec:
   #         f.write(l+'\n')
   # f.close()
   # args.input=inputF

    #args.input=os.getcwd()+'/input.txt'
    #print(args.input)
    args.sliding_P1=args.STtools+"/getSlidingGrid/slidingGrid_P1_V1.R"
    args.sliding_P2=args.STtools+"/getSlidingGrid/slidingGrid_P2_V1.R"
    args.sliding_P3=args.STtools+"/getSlidingGrid/slidingGrid_P3_V1.R"
    if(os.path.isfile(args.sliding_P1)==False):
        raise ValueError("File --sliding_P1 does not exist")
   
    if(os.path.isfile(args.sliding_P2)==False):
        raise ValueError("File --sliding_P2 does not exist")
    
    if(os.path.isfile(args.sliding_P3)==False):
        raise ValueError("File --sliding_P3 does not exist")
    
    cmd5_1="Rscript {args.sliding_P1} {args.seqscope1st} {args.DGEdir} {args.spatial} {args.outpath} {args.tiles}".format(args=args)
    ret = os.system(cmd5_1)
    if ( ret != 0 ):
        raise ValueError(f"ERROR in running {cmd5_1}, returning exit code {ret}")

    args.input=os.getcwd()+'/groupgrids_tile.txt'
    cmd5_2='cat {args.input} | xargs -I [] -P {args.cores} bash -c "Rscript {args.sliding_P2} {args.collapsePath} {args.DGEdir} {args.outpath} {args.window} {args.sidesize} []"'.format(args=args)
    ret = os.system(cmd5_2)
    if ( ret != 0 ):
        raise ValueError(f"ERROR in running {cmd5_2}, returning exit code {ret}")

    cmd5_3 = "Rscript {args.sliding_P3} {args.outpath} {args.ncol} {args.nrow}".format(args=args)
    ret = os.system(cmd5_3)
    if ( ret != 0 ):
        raise ValueError(f"ERROR in running {cmd5_3}, returning exit code {ret}\
")



def step6():
    print('Start clustering and mapping')
    args.workingdir = os.getcwd()
    if(args.simpleGridsPath is None):
        args.simpleGridsPath = args.workingdir+'SimpleSquareGrids.RDS'
    
    if(args.slidingGridsPath is None):
        args.slidingGridsPath = args.workingdir+'SlidingSquareGrids.RDS'
    if(args.geneCount1 is None):
        args.geneCount1=0
    if(args.geneCount2 is None):
        args.geneCount2=0
    if(args.nFeaturePlotOnly is None):
        args.nFeaturePlotOnly = 'FALSE'
    if(os.path.isfile(args.slidingGridsPath)==False):
        raise ValueError("Path --slidingGridsPath does not exist")
    if(os.path.isfile(args.simpleGridsPath)==False):
        raise ValueError("Path --simpleGridsPath does not exist")
    #print(args.slidingGridsPath)
    args.clus=args.STtools+'clusterAndMap/clusterAndMap.R'
    
    cmd = "Rscript {args.clus} {args.workingdir} {args.simpleGridsPath} {args.slidingGridsPath} {args.geneCount1} {args.geneCount2} {args.nFeaturePlotOnly}".format(args=args)
    ret = os.system(cmd)
    if(ret!=0):
        raise ValueError (f"ERROR in running {cmd}, returning exit code {ret}")


    
       
def step7():
    print('Start subcellular analysis!')
    if(args.subDGEdir is None):
        args.subDGEdir=os.getcwd()+"/"+args.outprefix+"Solo.out/Velocyto/raw/"
    print(args.subDGEdir)
    if(os.path.isdir(args.subDGEdir)==False):
        raise ValueError("Directory --subDGEdir does not exist")
    if(args.spatial is None):
        args.spatial=os.getcwd()+"/spatialcoordinates.txt"
    if(os.path.isfile(args.spatial)==False):
        raise ValueError("File --spatial does not exist")
    args.subana=args.STtools+"/subCellularAna/subCellularAna.py"
    args.workingdir=os.getcwd()
    if(('seqscope1st' in vars(args))==False):
        args.seqscope1st='MiSeq'  
    if(args.tiles is None):
        raise ValueError("Tiles are required")
    args.tiles_vec =args.tiles.split(',')


    cmd6="Rscript {args.py} {args.subana} {args.subDGEdir} {args.workingdir} {args.spatial} {args.seqscope1st} {args.tiles_vec} {args.alpha}".format(args=args)
    ret = os.system(cmd6)
    if ( ret != 0 ):
        raise ValueError(f"ERROR in running {cmd6}, returning exit code {ret}")



args = parser.parse_args()
steps = []
if ( args.run_steps is not None ):
    steps = [int(x) for x in args.run_steps.split(',')]
    n_steps=len(steps)
    print(n_steps)
    s_steps=sorted(steps)
  #if only one step
    if (set(steps).issubset(set(range(1,8))) ==False):
        print('Steps must be in the range from 1 to 7!')
    if (n_steps==1):
        print('Run step', steps[0])
        func=eval("step"+str(steps[0]))
        func()
    elif (s_steps == list(range(min(steps), max(steps)+1))):
        print('Run the following consecutive steps', s_steps)
        for i in s_steps:
            print(i)
            func=eval("step"+str(i))
            func()
    else:
        print('Please provide consecutive steps!')

#     print("Running the following steps: ", steps)
if ( args.run_all ):
   # steps = [1,2,3,4,5]
    print("Running the following steps: ", steps)

    ## check whether parameter is given
    if ( args.seq1 is None ):
        raise ValueError("Cannot find --seq1 argument. Need to specify for running all")
    if ( args.fq1 is None ):
        raise ValueError("Cannot find --fq1 argument. Need to specify for running all")
    if ( args.fq2 is None ):
        raise ValueError("Cannot find --fq2 argument. Need to specify for running all")
    if ( args.genome is None ):
        raise ValueError("Cannot find --genome argument. Need to specify for running all")

    #check file/directory path exist:
    if(os.path.isfile(args.seq1)==False):
        raise ValueError("File --seq1 does not exist")
    if(os.path.isfile(args.fq1)==False):
        raise ValueError("File --fq1 does not exist")
    if(os.path.isfile(args.fq2)==False):
        raise ValueError("File --fq2 does not exist")
    if(os.path.isdir(args.star_path)==False):
        raise ValueError("Directory --star-path does not exist")
    if(os.path.isdir(args.seqtk_path)==False):
        raise ValueError("Directory --seqtk-path does not exist")
    if(os.path.isdir(args.genome)==False):
        raise ValueError("Directory --genome does not exist")
    if(os.path.isdir(args.STtools)==False):
        raise ValueError("Directory --STtools does not exist")

    for i in range(1,8):
            print('Running step:' + i)
            func=eval("step"+str(i))
            func()