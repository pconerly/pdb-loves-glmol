_ = require 'underscore'
EventEmitter = require('events').EventEmitter
$ = require 'jquery'
Backbone = require 'backbone'
to_json = require('xmljson').to_json
GLmol = require './library/GLmol.js'

_life = {
  curPdbId: null
  config: {}
  results: {}
}


window._life = _life  # for debugging.

CHANGE_EVENT = 'changederp'

outer_iterate = ->
  AppStore.updateBoard()

AppStore = _.extend({}, EventEmitter::, 

  config: (config) ->
    _life.config = _.extend _life.config, config

  setPdbId: (query) ->
    _life.curPdbId = query
    @emitChange()

  fetch: (query) ->
    console.log "fething #{query}"
    _life.curPdbId = query

    @fetchDescription query
    @fetchPdb query

  fetchDescription: (query) ->
    _life.results[query] ?= {}

    $.ajax
      url: "http://www.rcsb.org/pdb/rest/describePDB?structureId=#{query}"
      method: 'GET'
      dataType: 'text' # it's xml, but we want the string
      crossDomain: true
      error: (xhr, status, error) =>
        console.log "error"
        console.log error
        @emitChange()
      success: (data, status) =>
        if status is "success"
          jsondata = to_json data, (message, data) =>
            if _.has data.PDBdescription, 'PDB'
              _life.results[query].description = data
            @emitChange()

  fetchPdb: (query) ->
    _life.results[query] ?= {}
    _life.results[query].glmol = new GLmol("glmol_#{query}", true)
    
    _life.results[query].glmol.initializeScene()

    $.ajax
      url: "http://www.pdb.org/pdb/files/#{query}.pdb"
      method: 'GET'
      dataType: 'text'
      crossDomain: true
      error: (xhr, status, error) =>
        console.log "error"
        console.log error
      success: (data, status) =>
        if status is "success"
          _life.results[query].pdbfile = data
          @emitChange()

    # interesting rest endpoints:
    # http://www.rcsb.org/pdb/rest/describePDB?structureId=4hhb&json=true

  search: (value) ->
    Backbone.history.navigate "pdb-id/#{value}",
      trigger: true

  getState: ->
    item = null
    if _.has _life.results, _life.curPdbId
      item = _life.results[_life.curPdbId]

    return _.extend _life, {
      item: item
    }

  emitChange: () ->
    @emit CHANGE_EVENT

  ###*
  @param {function} callback
  ###
  addChangeListener: (callback) ->
    @on CHANGE_EVENT, callback
    return

  ###*
  @param {function} callback
  ###
  removeChangeListener: (callback) ->
    @removeListener CHANGE_EVENT, callback
    return

)

module.exports = AppStore

window.pdbfile = """
HEADER    OXYGEN STORAGE/TRANSPORT                06-NOV-98   1B0B              
TITLE     HEMOGLOBIN I FROM THE CLAM LUCINA PECTINATA, CYANIDE                  
TITLE    2 COMPLEX AT 100 KELVIN                                                
COMPND    MOL_ID: 1;                                                            
COMPND   2 MOLECULE: HEMOGLOBIN;                                                
COMPND   3 CHAIN: A                                                             
SOURCE    MOL_ID: 1;                                                            
SOURCE   2 ORGANISM_SCIENTIFIC: LUCINA PECTINATA;                               
SOURCE   3 ORGANISM_TAXID: 29163                                                
KEYWDS    HEMOPROTEIN, SULFIDE CARRIER, GLOBINS, OXYGEN TRANSPORT,              
KEYWDS   2 OXYGEN STORAGE/TRANSPORT COMPLEX                                     
EXPDTA    X-RAY DIFFRACTION                                                     
AUTHOR    C.ROSANO,M.RIZZI,P.ASCENZI,M.BOLOGNESI                                
REVDAT   3   24-FEB-09 1B0B    1       VERSN                                    
REVDAT   2   01-APR-03 1B0B    1       JRNL                                     
REVDAT   1   18-FEB-00 1B0B    0                                                
JRNL        AUTH   M.BOLOGNESI,C.ROSANO,R.LOSSO,A.BORASSI,M.RIZZI,              
JRNL        AUTH 2 J.B.WITTENBERG,A.BOFFI,P.ASCENZI                             
JRNL        TITL   CYANIDE BINDING TO LUCINA PECTINATA HEMOGLOBIN I             
JRNL        TITL 2 AND TO SPERM WHALE MYOGLOBIN: AN X-RAY                       
JRNL        TITL 3 CRYSTALLOGRAPHIC STUDY.                                      
JRNL        REF    BIOPHYS.J.                    V.  77  1093 1999              
JRNL        REFN                   ISSN 0006-3495                               
JRNL        PMID   10423453                                                     
REMARK   1                                                                      
REMARK   2                                                                      
REMARK   2 RESOLUTION.    1.43 ANGSTROMS.                                       
REMARK   3                                                                      
REMARK   3 REFINEMENT.                                                          
REMARK   3   PROGRAM     : SHELXL-97                                            
REMARK   3   AUTHORS     : G.M.SHELDRICK                                        
REMARK   3                                                                      
REMARK   3  DATA USED IN REFINEMENT.                                            
REMARK   3   RESOLUTION RANGE HIGH (ANGSTROMS) : 1.43                           
REMARK   3   RESOLUTION RANGE LOW  (ANGSTROMS) : 8.00                           
REMARK   3   DATA CUTOFF            (SIGMA(F)) : NULL                           
REMARK   3   COMPLETENESS FOR RANGE        (%) : 92.3                           
REMARK   3   CROSS-VALIDATION METHOD           : NULL                           
REMARK   3   FREE R VALUE TEST SET SELECTION   : NULL                           
REMARK   3                                                                      
REMARK   3  FIT TO DATA USED IN REFINEMENT (NO CUTOFF).                         
REMARK   3   R VALUE   (WORKING + TEST SET, NO CUTOFF) : NULL                   
REMARK   3   R VALUE          (WORKING SET, NO CUTOFF) : 0.119                  
REMARK   3   FREE R VALUE                  (NO CUTOFF) : 0.170                  
REMARK   3   FREE R VALUE TEST SET SIZE (%, NO CUTOFF) : 5.000                  
REMARK   3   FREE R VALUE TEST SET COUNT   (NO CUTOFF) : 1340                   
REMARK   3   TOTAL NUMBER OF REFLECTIONS   (NO CUTOFF) : 26805                  
REMARK   3                                                                      
REMARK   3  FIT/AGREEMENT OF MODEL FOR DATA WITH F>4SIG(F).                     
REMARK   3   R VALUE   (WORKING + TEST SET, F>4SIG(F)) : NULL                   
REMARK   3   R VALUE          (WORKING SET, F>4SIG(F)) : 0.110                  
REMARK   3   FREE R VALUE                  (F>4SIG(F)) : 0.160                  
REMARK   3   FREE R VALUE TEST SET SIZE (%, F>4SIG(F)) : NULL                   
REMARK   3   FREE R VALUE TEST SET COUNT   (F>4SIG(F)) : 1132                   
REMARK   3   TOTAL NUMBER OF REFLECTIONS   (F>4SIG(F)) : 21186                  
REMARK   3                                                                      
REMARK   3  NUMBER OF NON-HYDROGEN ATOMS USED IN REFINEMENT.                    
REMARK   3   PROTEIN ATOMS      : 1060                                          
REMARK   3   NUCLEIC ACID ATOMS : 0                                             
REMARK   3   HETEROGEN ATOMS    : 45                                            
REMARK   3   SOLVENT ATOMS      : 202                                           
REMARK   3                                                                      
REMARK   3  MODEL REFINEMENT.                                                   
REMARK   3   OCCUPANCY SUM OF NON-HYDROGEN ATOMS      : NULL                    
REMARK   3   OCCUPANCY SUM OF HYDROGEN ATOMS          : NULL                    
REMARK   3   NUMBER OF DISCRETELY DISORDERED RESIDUES : 8                       
REMARK   3   NUMBER OF LEAST-SQUARES PARAMETERS       : NULL                    
REMARK   3   NUMBER OF RESTRAINTS                     : NULL                    
REMARK   3                                                                      
REMARK   3  RMS DEVIATIONS FROM RESTRAINT TARGET VALUES.                        
REMARK   3   BOND LENGTHS                         (A) : 0.019                   
REMARK   3   ANGLE DISTANCES                      (A) : 0.038                   
REMARK   3   SIMILAR DISTANCES (NO TARGET VALUES) (A) : NULL                    
REMARK   3   DISTANCES FROM RESTRAINT PLANES      (A) : NULL                    
REMARK   3   ZERO CHIRAL VOLUMES               (A**3) : NULL                    
REMARK   3   NON-ZERO CHIRAL VOLUMES           (A**3) : NULL                    
REMARK   3   ANTI-BUMPING DISTANCE RESTRAINTS     (A) : NULL                    
REMARK   3   RIGID-BOND ADP COMPONENTS         (A**2) : NULL                    
REMARK   3   SIMILAR ADP COMPONENTS            (A**2) : NULL                    
REMARK   3   APPROXIMATELY ISOTROPIC ADPS      (A**2) : NULL                    
REMARK   3                                                                      
REMARK   3  BULK SOLVENT MODELING.                                              
REMARK   3   METHOD USED: NULL                                                  
REMARK   3                                                                      
REMARK   3  STEREOCHEMISTRY TARGET VALUES : NULL                                
REMARK   3   SPECIAL CASE: NULL                                                 
REMARK   3                                                                      
REMARK   3  OTHER REFINEMENT REMARKS: NULL                                      
REMARK   4                                                                      
REMARK   4 1B0B COMPLIES WITH FORMAT V. 3.15, 01-DEC-08                         
REMARK 100                                                                      
REMARK 100 THIS ENTRY HAS BEEN PROCESSED BY BNL.                                
REMARK 200                                                                      
REMARK 200 EXPERIMENTAL DETAILS                                                 
REMARK 200  EXPERIMENT TYPE                : X-RAY DIFFRACTION                  
REMARK 200  DATE OF DATA COLLECTION        : JUL-98                             
REMARK 200  TEMPERATURE           (KELVIN) : 100                                
REMARK 200  PH                             : 6.5                                
REMARK 200  NUMBER OF CRYSTALS USED        : 1                                  
REMARK 200                                                                      
REMARK 200  SYNCHROTRON              (Y/N) : Y                                  
REMARK 200  RADIATION SOURCE               : EMBL/DESY, HAMBURG                 
REMARK 200  BEAMLINE                       : BW7A                               
REMARK 200  X-RAY GENERATOR MODEL          : NULL                               
REMARK 200  MONOCHROMATIC OR LAUE    (M/L) : M                                  
REMARK 200  WAVELENGTH OR RANGE        (A) : 0.980                              
REMARK 200  MONOCHROMATOR                  : NULL                               
REMARK 200  OPTICS                         : NULL                               
REMARK 200                                                                      
REMARK 200  DETECTOR TYPE                  : NULL                               
REMARK 200  DETECTOR MANUFACTURER          : NULL                               
REMARK 200  INTENSITY-INTEGRATION SOFTWARE : DENZO                              
REMARK 200  DATA SCALING SOFTWARE          : SCALEPACK                          
REMARK 200                                                                      
REMARK 200  NUMBER OF UNIQUE REFLECTIONS   : 29097                              
REMARK 200  RESOLUTION RANGE HIGH      (A) : 1.430                              
REMARK 200  RESOLUTION RANGE LOW       (A) : 20.000                             
REMARK 200  REJECTION CRITERIA  (SIGMA(I)) : NULL                               
REMARK 200                                                                      
REMARK 200 OVERALL.                                                             
REMARK 200  COMPLETENESS FOR RANGE     (%) : 92.3                               
REMARK 200  DATA REDUNDANCY                : 3.400                              
REMARK 200  R MERGE                    (I) : 0.04700                            
REMARK 200  R SYM                      (I) : NULL                               
REMARK 200  <I/SIGMA(I)> FOR THE DATA SET  : 9.1000                             
REMARK 200                                                                      
REMARK 200 IN THE HIGHEST RESOLUTION SHELL.                                     
REMARK 200  HIGHEST RESOLUTION SHELL, RANGE HIGH (A) : NULL                     
REMARK 200  HIGHEST RESOLUTION SHELL, RANGE LOW  (A) : NULL                     
REMARK 200  COMPLETENESS FOR SHELL     (%) : NULL                               
REMARK 200  DATA REDUNDANCY IN SHELL       : NULL                               
REMARK 200  R MERGE FOR SHELL          (I) : NULL                               
REMARK 200  R SYM FOR SHELL            (I) : NULL                               
REMARK 200  <I/SIGMA(I)> FOR SHELL         : NULL                               
REMARK 200                                                                      
REMARK 200 DIFFRACTION PROTOCOL: NULL                                           
REMARK 200 METHOD USED TO DETERMINE THE STRUCTURE: NULL                         
REMARK 200 SOFTWARE USED: SHELXL-97                                             
REMARK 200 STARTING MODEL: NULL                                                 
REMARK 200                                                                      
REMARK 200 REMARK: NULL                                                         
REMARK 280                                                                      
REMARK 280 CRYSTAL                                                              
REMARK 280 SOLVENT CONTENT, VS   (%): 57.00                                     
REMARK 280 MATTHEWS COEFFICIENT, VM (ANGSTROMS**3/DA): 2.33                     
REMARK 280                                                                      
REMARK 280 CRYSTALLIZATION CONDITIONS: PH 6.5                                   
REMARK 290                                                                      
REMARK 290 CRYSTALLOGRAPHIC SYMMETRY                                            
REMARK 290 SYMMETRY OPERATORS FOR SPACE GROUP: P 1 21 1                         
REMARK 290                                                                      
REMARK 290      SYMOP   SYMMETRY                                                
REMARK 290     NNNMMM   OPERATOR                                                
REMARK 290       1555   X,Y,Z                                                   
REMARK 290       2555   -X,Y+1/2,-Z                                             
REMARK 290                                                                      
REMARK 290     WHERE NNN -> OPERATOR NUMBER                                     
REMARK 290           MMM -> TRANSLATION VECTOR                                  
REMARK 290                                                                      
REMARK 290 CRYSTALLOGRAPHIC SYMMETRY TRANSFORMATIONS                            
REMARK 290 THE FOLLOWING TRANSFORMATIONS OPERATE ON THE ATOM/HETATM             
REMARK 290 RECORDS IN THIS ENTRY TO PRODUCE CRYSTALLOGRAPHICALLY                
REMARK 290 RELATED MOLECULES.                                                   
REMARK 290   SMTRY1   1  1.000000  0.000000  0.000000        0.00000            
REMARK 290   SMTRY2   1  0.000000  1.000000  0.000000        0.00000            
REMARK 290   SMTRY3   1  0.000000  0.000000  1.000000        0.00000            
REMARK 290   SMTRY1   2 -1.000000  0.000000  0.000000        0.00000            
REMARK 290   SMTRY2   2  0.000000  1.000000  0.000000       18.97500            
REMARK 290   SMTRY3   2  0.000000  0.000000 -1.000000        0.00000            
REMARK 290                                                                      
REMARK 290 REMARK: NULL                                                         
REMARK 300                                                                      
REMARK 300 BIOMOLECULE: 1                                                       
REMARK 300 SEE REMARK 350 FOR THE AUTHOR PROVIDED AND/OR PROGRAM                
REMARK 300 GENERATED ASSEMBLY INFORMATION FOR THE STRUCTURE IN                  
REMARK 300 THIS ENTRY. THE REMARK MAY ALSO PROVIDE INFORMATION ON               
REMARK 300 BURIED SURFACE AREA.                                                 
REMARK 350                                                                      
REMARK 350 COORDINATES FOR A COMPLETE MULTIMER REPRESENTING THE KNOWN           
REMARK 350 BIOLOGICALLY SIGNIFICANT OLIGOMERIZATION STATE OF THE                
REMARK 350 MOLECULE CAN BE GENERATED BY APPLYING BIOMT TRANSFORMATIONS          
REMARK 350 GIVEN BELOW.  BOTH NON-CRYSTALLOGRAPHIC AND                          
REMARK 350 CRYSTALLOGRAPHIC OPERATIONS ARE GIVEN.                               
REMARK 350                                                                      
REMARK 350 BIOMOLECULE: 1                                                       
REMARK 350 AUTHOR DETERMINED BIOLOGICAL UNIT: MONOMERIC                         
REMARK 350 APPLY THE FOLLOWING TO CHAINS: A                                     
REMARK 350   BIOMT1   1  1.000000  0.000000  0.000000        0.00000            
REMARK 350   BIOMT2   1  0.000000  1.000000  0.000000        0.00000            
REMARK 350   BIOMT3   1  0.000000  0.000000  1.000000        0.00000            
REMARK 500                                                                      
REMARK 500 GEOMETRY AND STEREOCHEMISTRY                                         
REMARK 500 SUBTOPIC: CLOSE CONTACTS IN SAME ASYMMETRIC UNIT                     
REMARK 500                                                                      
REMARK 500 THE FOLLOWING ATOMS ARE IN CLOSE CONTACT.                            
REMARK 500                                                                      
REMARK 500  ATM1  RES C  SSEQI   ATM2  RES C  SSEQI           DISTANCE          
REMARK 500   CE   LYS A    11     O    HOH A   648              1.58            
REMARK 500                                                                      
REMARK 500 REMARK: NULL                                                         
REMARK 500                                                                      
REMARK 500 GEOMETRY AND STEREOCHEMISTRY                                         
REMARK 500 SUBTOPIC: COVALENT BOND LENGTHS                                      
REMARK 500                                                                      
REMARK 500 THE STEREOCHEMICAL PARAMETERS OF THE FOLLOWING RESIDUES              
REMARK 500 HAVE VALUES WHICH DEVIATE FROM EXPECTED VALUES BY MORE               
REMARK 500 THAN 6*RMSD (M=MODEL NUMBER; RES=RESIDUE NAME; C=CHAIN               
REMARK 500 IDENTIFIER; SSEQ=SEQUENCE NUMBER; I=INSERTION CODE).                 
REMARK 500                                                                      
REMARK 500 STANDARD TABLE:                                                      
REMARK 500 FORMAT: (10X,I3,1X,2(A3,1X,A1,I4,A1,1X,A4,3X),1X,F6.3)               
REMARK 500                                                                      
REMARK 500 EXPECTED VALUES PROTEIN: ENGH AND HUBER, 1999                        
REMARK 500 EXPECTED VALUES NUCLEIC ACID: CLOWNEY ET AL 1996                     
REMARK 500                                                                      
REMARK 500  M RES CSSEQI ATM1   RES CSSEQI ATM2   DEVIATION                     
REMARK 500    ALA A 109   CA    ALA A 109   CB      0.290                       
REMARK 500                                                                      
REMARK 500 REMARK: NULL                                                         
REMARK 500                                                                      
REMARK 500 GEOMETRY AND STEREOCHEMISTRY                                         
REMARK 500 SUBTOPIC: COVALENT BOND ANGLES                                       
REMARK 500                                                                      
REMARK 500 THE STEREOCHEMICAL PARAMETERS OF THE FOLLOWING RESIDUES              
REMARK 500 HAVE VALUES WHICH DEVIATE FROM EXPECTED VALUES BY MORE               
REMARK 500 THAN 6*RMSD (M=MODEL NUMBER; RES=RESIDUE NAME; C=CHAIN               
REMARK 500 IDENTIFIER; SSEQ=SEQUENCE NUMBER; I=INSERTION CODE).                 
REMARK 500                                                                      
REMARK 500 STANDARD TABLE:                                                      
REMARK 500 FORMAT: (10X,I3,1X,A3,1X,A1,I4,A1,3(1X,A4,2X),12X,F5.1)              
REMARK 500                                                                      
REMARK 500 EXPECTED VALUES PROTEIN: ENGH AND HUBER, 1999                        
REMARK 500 EXPECTED VALUES NUCLEIC ACID: CLOWNEY ET AL 1996                     
REMARK 500                                                                      
REMARK 500  M RES CSSEQI ATM1   ATM2   ATM3                                     
REMARK 500    GLU A  27   OE1 -  CD  -  OE2 ANGL. DEV. =   7.3 DEGREES          
REMARK 500    ARG A  99   NE  -  CZ  -  NH2 ANGL. DEV. =  -3.1 DEGREES          
REMARK 500                                                                      
REMARK 500 REMARK: NULL                                                         
REMARK 500                                                                      
REMARK 500 GEOMETRY AND STEREOCHEMISTRY                                         
REMARK 500 SUBTOPIC: PLANAR GROUPS                                              
REMARK 500                                                                      
REMARK 500 PLANAR GROUPS IN THE FOLLOWING RESIDUES HAVE A TOTAL                 
REMARK 500 RMS DISTANCE OF ALL ATOMS FROM THE BEST-FIT PLANE                    
REMARK 500 BY MORE THAN AN EXPECTED VALUE OF 6*RMSD, WITH AN                    
REMARK 500 RMSD 0.02 ANGSTROMS, OR AT LEAST ONE ATOM HAS                        
REMARK 500 AN RMSD GREATER THAN THIS VALUE                                      
REMARK 500 (M=MODEL NUMBER; RES=RESIDUE NAME; C=CHAIN IDENTIFIER;               
REMARK 500 SSEQ=SEQUENCE NUMBER; I=INSERTION CODE).                             
REMARK 500                                                                      
REMARK 500  M RES CSSEQI        RMS     TYPE                                    
REMARK 500    GLU A 107         0.12    SIDE_CHAIN                              
REMARK 500                                                                      
REMARK 500 REMARK: NULL                                                         
REMARK 525                                                                      
REMARK 525 SOLVENT                                                              
REMARK 525                                                                      
REMARK 525 THE SOLVENT MOLECULES HAVE CHAIN IDENTIFIERS THAT                    
REMARK 525 INDICATE THE POLYMER CHAIN WITH WHICH THEY ARE MOST                  
REMARK 525 CLOSELY ASSOCIATED. THE REMARK LISTS ALL THE SOLVENT                 
REMARK 525 MOLECULES WHICH ARE MORE THAN 5A AWAY FROM THE                       
REMARK 525 NEAREST POLYMER CHAIN (M = MODEL NUMBER;                             
REMARK 525 RES=RESIDUE NAME; C=CHAIN IDENTIFIER; SSEQ=SEQUENCE                  
REMARK 525 NUMBER; I=INSERTION CODE):                                           
REMARK 525                                                                      
REMARK 525  M RES CSSEQI                                                        
REMARK 525    HOH A 536        DISTANCE =  5.95 ANGSTROMS                       
REMARK 620                                                                      
REMARK 620 METAL COORDINATION                                                   
REMARK 620  (M=MODEL NUMBER; RES=RESIDUE NAME; C=CHAIN IDENTIFIER;              
REMARK 620  SSEQ=SEQUENCE NUMBER; I=INSERTION CODE):                            
REMARK 620                                                                      
REMARK 620 COORDINATION ANGLES FOR:  M RES CSSEQI METAL                         
REMARK 620                             HEM A 144  FE                            
REMARK 620 N RES CSSEQI ATOM                                                    
REMARK 620 1 HIS A  96   NE2                                                    
REMARK 620 2 CYN A 145   C   176.1                                              
REMARK 620 3 CYN A 145   N   175.4   0.9                                        
REMARK 620 N                    1     2                                         
REMARK 800                                                                      
REMARK 800 SITE                                                                 
REMARK 800 SITE_IDENTIFIER: AC1                                                 
REMARK 800 EVIDENCE_CODE: SOFTWARE                                              
REMARK 800 SITE_DESCRIPTION: BINDING SITE FOR RESIDUE CYN A 145                 
REMARK 800 SITE_IDENTIFIER: AC2                                                 
REMARK 800 EVIDENCE_CODE: SOFTWARE                                              
REMARK 800 SITE_DESCRIPTION: BINDING SITE FOR RESIDUE HEM A 144                 
DBREF  1B0B A    2   142  UNP    P41260   GLB1_LUCPE       2    142             
SEQADV 1B0B SER A    3  UNP  P41260    GLU     3 SEE REMARK 999                 
SEQADV 1B0B ASP A    8  UNP  P41260    SER     8 CONFLICT                       
SEQADV 1B0B LYS A   11  UNP  P41260    THR    11 SEE REMARK 999                 
SEQADV 1B0B ALA A  114  UNP  P41260    SER   114 SEE REMARK 999                 
SEQADV 1B0B MET A  137  UNP  P41260    GLU   137 SEE REMARK 999                 
SEQADV 1B0B ARG A  139  UNP  P41260    GLU   139 SEE REMARK 999                 
SEQRES   1 A  142  SAC LEU SER ALA ALA GLN LYS ASP ASN VAL LYS SER SER          
SEQRES   2 A  142  TRP ALA LYS ALA SER ALA ALA TRP GLY THR ALA GLY PRO          
SEQRES   3 A  142  GLU PHE PHE MET ALA LEU PHE ASP ALA HIS ASP ASP VAL          
SEQRES   4 A  142  PHE ALA LYS PHE SER GLY LEU PHE SER GLY ALA ALA LYS          
SEQRES   5 A  142  GLY THR VAL LYS ASN THR PRO GLU MET ALA ALA GLN ALA          
SEQRES   6 A  142  GLN SER PHE LYS GLY LEU VAL SER ASN TRP VAL ASP ASN          
SEQRES   7 A  142  LEU ASP ASN ALA GLY ALA LEU GLU GLY GLN CYS LYS THR          
SEQRES   8 A  142  PHE ALA ALA ASN HIS LYS ALA ARG GLY ILE SER ALA GLY          
SEQRES   9 A  142  GLN LEU GLU ALA ALA PHE LYS VAL LEU ALA GLY PHE MET          
SEQRES  10 A  142  LYS SER TYR GLY GLY ASP GLU GLY ALA TRP THR ALA VAL          
SEQRES  11 A  142  ALA GLY ALA LEU MET GLY MET ILE ARG PRO ASP MET              
MODRES 1B0B SAC A    1  SER  N-ACETYL-SERINE                                    
HET    SAC  A   1       9                                                       
HET    CYN  A 145       2                                                       
HET    HEM  A 144      43                                                       
HETNAM     SAC N-ACETYL-SERINE                                                  
HETNAM     CYN CYANIDE ION                                                      
HETNAM     HEM PROTOPORPHYRIN IX CONTAINING FE                                  
HETSYN     HEM HEME                                                             
FORMUL   1  SAC    C5 H9 N O4                                                   
FORMUL   2  CYN    C N 1-                                                       
FORMUL   3  HEM    C34 H32 FE N4 O4                                             
FORMUL   4  HOH   *202(H2 O)                                                    
HELIX    1   1 ALA A    4  ALA A   19  1                                  16    
HELIX    2   2 TRP A   21  ALA A   35  1                                  15    
HELIX    3   3 ASP A   37  PHE A   43  1                                   7    
HELIX    4   4 LYS A   52  THR A   54  5                                   3    
HELIX    5   5 PRO A   59  ASN A   78  1                                  20    
HELIX    6   6 ALA A   82  ARG A   99  1                                  18    
HELIX    7   7 ALA A  103  TYR A  120  1                                  18    
HELIX    8   8 GLU A  124  ILE A  138  1                                  15    
LINK         C   SAC A   1                 N   LEU A   2     1555   1555  1.33  
LINK        FE   HEM A 144                 NE2 HIS A  96     1555   1555  2.13  
LINK        FE   HEM A 144                 C   CYN A 145     1555   1555  1.95  
LINK        FE   HEM A 144                 N   CYN A 145     1555   1555  3.10  
SITE     1 AC1  4 PHE A  29  PHE A  43  GLN A  64  HEM A 144                    
SITE     1 AC2 17 LYS A  42  PHE A  43  GLN A  64  SER A  67                    
SITE     2 AC2 17 PHE A  68  PHE A  92  ASN A  95  HIS A  96                    
SITE     3 AC2 17 ARG A  99  ILE A 101  GLN A 105  CYN A 145                    
SITE     4 AC2 17 HOH A 503  HOH A 577  HOH A 581  HOH A 637                    
SITE     5 AC2 17 HOH A 669                                                     
CRYST1   49.440   37.950   41.370  90.00 106.19  90.00 P 1 21 1      2          
ORIGX1      1.000000  0.000000  0.000000        0.00000                         
ORIGX2      0.000000  1.000000  0.000000        0.00000                         
ORIGX3      0.000000  0.000000  1.000000        0.00000                         
SCALE1      0.020227  0.000000  0.005873        0.00000                         
SCALE2      0.000000  0.026350  0.000000        0.00000                         
SCALE3      0.000000  0.000000  0.025170        0.00000                         
HETATM    1  C1A SAC A   1       0.309  21.624  12.084  1.00 14.46           C  
HETATM    2  C2A SAC A   1      -0.644  22.786  12.305  1.00 16.17           C  
HETATM    3  OAC SAC A   1       0.748  21.270  10.965  1.00 15.17           O  
HETATM    4  N   SAC A   1       0.704  20.902  13.201  1.00 12.52           N  
HETATM    5  CA  SAC A   1       1.696  19.854  13.115  1.00 11.35           C  
HETATM    6  C   SAC A   1       1.153  18.571  12.512  1.00 11.11           C  
HETATM    7  O   SAC A   1       2.005  17.715  12.278  1.00 14.64           O  
HETATM    8  CB  SAC A   1       2.243  19.544  14.508  1.00 13.32           C  
HETATM    9  OG  SAC A   1       1.224  19.038  15.329  1.00 18.68           O  
ATOM     10  N   LEU A   2      -0.158  18.399  12.345  1.00  7.96           N  
ATOM     11  CA  LEU A   2      -0.697  17.211  11.672  1.00  7.30           C  
ATOM     12  C   LEU A   2      -1.965  17.582  10.905  1.00  7.61           C  
ATOM     13  O   LEU A   2      -2.995  17.844  11.520  1.00 10.60           O  
ATOM     14  CB  LEU A   2      -0.944  16.101  12.670  1.00  7.78           C  
ATOM     15  CG  LEU A   2      -1.508  14.802  12.076  1.00  9.10           C  
ATOM     16  CD1 LEU A   2      -0.545  14.205  11.061  1.00  9.71           C  
ATOM     17  CD2 LEU A   2      -1.827  13.837  13.207  1.00 11.22           C  
ATOM     18  N   SER A   3      -1.795  17.800   9.590  1.00  5.77           N  
ATOM     19  CA  SER A   3      -2.901  18.304   8.814  1.00  5.25           C  
ATOM     20  C   SER A   3      -3.937  17.243   8.455  1.00  4.75           C  
ATOM     21  O   SER A   3      -3.652  16.051   8.459  1.00  5.56           O  
ATOM     22  CB  SER A   3      -2.422  18.974   7.530  1.00  5.49           C  
ATOM     23  OG  SER A   3      -2.065  17.973   6.625  1.00  6.35           O  
ATOM     24  N   ALA A   4      -5.131  17.739   8.075  1.00  6.25           N  
ATOM     25  CA  ALA A   4      -6.157  16.796   7.625  1.00  6.20           C  
ATOM     26  C   ALA A   4      -5.695  15.952   6.436  1.00  6.23           C  
ATOM     27  O   ALA A   4      -5.985  14.759   6.372  1.00  6.85           O  
ATOM     28  CB  ALA A   4      -7.420  17.541   7.231  1.00  7.62           C  
ATOM     29  N   ALA A   5      -4.979  16.610   5.528  1.00  6.00           N  
ATOM     30  CA  ALA A   5      -4.482  15.920   4.350  1.00  5.18           C  
ATOM     31  C   ALA A   5      -3.468  14.852   4.773  1.00  5.38           C  
ATOM     32  O   ALA A   5      -3.368  13.810   4.089  1.00  5.51           O  
ATOM     33  CB  ALA A   5      -3.907  16.851   3.290  1.00  8.06           C  
ATOM     34  N   GLN A   6      -2.558  15.177   5.673  1.00  5.23           N  
ATOM     35  CA  GLN A   6      -1.571  14.191   6.129  1.00  5.19           C  
ATOM     36  C   GLN A   6      -2.282  13.000   6.737  1.00  4.49           C  
ATOM     37  O   GLN A   6      -1.900  11.856   6.488  1.00  4.77           O  
ATOM     38  CB  GLN A   6      -0.609  14.815   7.125  1.00  5.19           C  
ATOM     39  CG  GLN A   6       0.334  15.824   6.453  1.00  5.92           C  
ATOM     40  CD  GLN A   6       1.220  16.544   7.444  1.00  6.11           C  
ATOM     41  OE1 GLN A   6       0.811  17.057   8.471  1.00  7.42           O  
ATOM     42  NE2 GLN A   6       2.503  16.650   7.114  1.00  7.41           N  
ATOM     43  N   LYS A   7      -3.278  13.271   7.591  1.00  4.60           N  
ATOM     44  CA  LYS A   7      -4.023  12.146   8.172  1.00  4.79           C  
ATOM     45  C   LYS A   7      -4.671  11.294   7.101  1.00  4.89           C  
ATOM     46  O   LYS A   7      -4.699  10.070   7.187  1.00  5.64           O  
ATOM     47  CB  LYS A   7      -5.035  12.723   9.137  1.00  5.53           C  
ATOM     48  CG  LYS A   7      -4.507  13.456  10.339  1.00  5.93           C  
ATOM     49  CD  LYS A   7      -5.669  14.106  11.084  1.00  8.65           C  
ATOM     50  CE  LYS A   7      -5.237  14.835  12.332  1.00  9.73           C  
ATOM     51  NZ  LYS A   7      -6.380  15.539  12.992  1.00 10.72           N  
ATOM     52  N   ASP A   8      -5.315  11.956   6.146  1.00  5.25           N  
ATOM     53  CA  ASP A   8      -6.000  11.216   5.083  1.00  5.55           C  
ATOM     54  C   ASP A   8      -5.004  10.325   4.324  1.00  5.15           C  
ATOM     55  O   ASP A   8      -5.322   9.208   3.945  1.00  6.49           O  
ATOM     56  CB  ASP A   8      -6.750  12.147   4.142  1.00  6.87           C  
ATOM     57  CG  ASP A   8      -7.981  12.831   4.714  1.00  8.87           C  
ATOM     58  OD1 ASP A   8      -8.517  12.298   5.710  1.00 13.81           O  
ATOM     59  OD2 ASP A   8      -8.440  13.834   4.063  1.00 10.94           O  
ATOM     60  N   ASN A   9      -3.831  10.861   3.973  1.00  4.96           N  
ATOM     61  CA  ASN A   9      -2.834  10.079   3.279  1.00  4.58           C  
ATOM     62  C   ASN A   9      -2.372   8.877   4.088  1.00  4.70           C  
ATOM     63  O   ASN A   9      -2.157   7.803   3.534  1.00  5.20           O  
ATOM     64  CB  ASN A   9      -1.615  10.935   2.899  1.00  4.73           C  
ATOM     65  CG  ASN A   9      -0.472  10.128   2.327  1.00  4.41           C  
ATOM     66  OD1 ASN A   9       0.455   9.741   3.061  1.00  6.38           O  
ATOM     67  ND2 ASN A   9      -0.359   9.944   1.016  1.00  7.16           N  
ATOM     68  N   VAL A  10      -2.120   9.104   5.371  1.00  4.89           N  
ATOM     69  CA  VAL A  10      -1.716   8.005   6.261  1.00  5.47           C  
ATOM     70  C   VAL A  10      -2.804   6.941   6.324  1.00  5.39           C  
ATOM     71  O   VAL A  10      -2.538   5.740   6.173  1.00  5.49           O  
ATOM     72  CB  VAL A  10      -1.333   8.569   7.632  1.00  5.02           C  
ATOM     73  CG1 VAL A  10      -1.203   7.479   8.696  1.00  6.23           C  
ATOM     74  CG2 VAL A  10      -0.004   9.306   7.572  1.00  5.65           C  
ATOM     75  N   LYS A  11      -4.066   7.332   6.497  1.00  6.44           N  
ATOM     76  CA  LYS A  11      -5.120   6.335   6.521  1.00  8.09           C  
ATOM     77  C   LYS A  11      -5.243   5.533   5.233  1.00  7.31           C  
ATOM     78  O   LYS A  11      -5.426   4.340   5.265  1.00  7.00           O  
ATOM     79  CB ALYS A  11      -6.456   7.055   6.806  0.50 10.91           C  
ATOM     80  CB BLYS A  11      -6.452   6.989   6.841  0.50 10.81           C  
ATOM     81  CG ALYS A  11      -6.541   7.753   8.137  0.50 13.48           C  
ATOM     82  CG BLYS A  11      -7.514   6.004   7.311  0.50 11.97           C  
ATOM     83  CD ALYS A  11      -7.893   8.418   8.354  0.50 20.20           C  
ATOM     84  CD BLYS A  11      -8.653   6.702   8.037  0.50 13.75           C  
ATOM     85  CE ALYS A  11      -7.924   9.844   7.847  0.50 26.53           C  
ATOM     86  CE BLYS A  11      -9.694   5.697   8.509  0.50 17.12           C  
ATOM     87  NZ ALYS A  11      -8.987  10.107   6.798  0.50 27.08           N  
ATOM     88  NZ BLYS A  11     -11.063   6.278   8.554  0.50 15.12           N  
ATOM     89  N   SER A  12      -5.184   6.242   4.117  1.00  6.32           N  
ATOM     90  CA  SER A  12      -5.422   5.625   2.822  1.00  6.15           C  
ATOM     91  C   SER A  12      -4.245   4.760   2.436  1.00  5.34           C  
ATOM     92  O   SER A  12      -4.431   3.694   1.887  1.00  6.57           O  
ATOM     93  CB ASER A  12      -5.727   6.718   1.795  0.50  6.31           C  
ATOM     94  CB BSER A  12      -5.693   6.651   1.721  0.50  7.22           C  
ATOM     95  OG ASER A  12      -6.984   7.345   2.047  0.50 10.00           O  
ATOM     96  OG BSER A  12      -5.493   6.087   0.430  0.50  8.22           O  
ATOM     97  N   SER A  13      -3.020   5.264   2.690  1.00  5.04           N  
ATOM     98  CA  SER A  13      -1.876   4.425   2.350  1.00  5.31           C  
ATOM     99  C   SER A  13      -1.757   3.231   3.294  1.00  4.70           C  
ATOM    100  O   SER A  13      -1.421   2.152   2.829  1.00  4.90           O  
ATOM    101  CB ASER A  13      -0.612   5.289   2.336  0.50  5.32           C  
ATOM    102  CB BSER A  13      -0.585   5.215   2.229  0.50  6.40           C  
ATOM    103  OG ASER A  13      -0.259   5.866   3.594  0.50  4.98           O  
ATOM    104  OG BSER A  13      -0.376   5.600   0.879  0.50  7.64           O  
ATOM    105  N   TRP A  14      -2.114   3.422   4.570  1.00  4.47           N  
ATOM    106  CA  TRP A  14      -2.166   2.290   5.493  1.00  5.48           C  
ATOM    107  C   TRP A  14      -3.158   1.231   5.020  1.00  5.66           C  
ATOM    108  O   TRP A  14      -2.900   0.030   5.080  1.00  6.28           O  
ATOM    109  CB  TRP A  14      -2.469   2.694   6.960  1.00  5.22           C  
ATOM    110  CG  TRP A  14      -2.323   1.438   7.794  1.00  4.48           C  
ATOM    111  CD1 TRP A  14      -3.299   0.824   8.510  1.00  5.50           C  
ATOM    112  CD2 TRP A  14      -1.137   0.644   7.976  1.00  4.95           C  
ATOM    113  NE1 TRP A  14      -2.805  -0.306   9.139  1.00  6.46           N  
ATOM    114  CE2 TRP A  14      -1.480  -0.428   8.815  1.00  6.41           C  
ATOM    115  CE3 TRP A  14       0.192   0.679   7.545  1.00  5.62           C  
ATOM    116  CZ2 TRP A  14      -0.566  -1.403   9.199  1.00  7.04           C  
ATOM    117  CZ3 TRP A  14       1.118  -0.289   7.920  1.00  5.89           C  
ATOM    118  CH2 TRP A  14       0.727  -1.349   8.763  1.00  6.88           C  
ATOM    119  N   ALA A  15      -4.296   1.643   4.469  1.00  6.14           N  
ATOM    120  CA  ALA A  15      -5.243   0.666   3.910  1.00  6.23           C  
ATOM    121  C   ALA A  15      -4.575  -0.181   2.832  1.00  6.58           C  
ATOM    122  O   ALA A  15      -4.815  -1.392   2.731  1.00  6.99           O  
ATOM    123  CB  ALA A  15      -6.483   1.362   3.394  1.00  5.52           C  
ATOM    124  N   LYS A  16      -3.751   0.431   1.995  1.00  5.99           N  
ATOM    125  CA  LYS A  16      -3.070  -0.279   0.955  1.00  6.63           C  
ATOM    126  C   LYS A  16      -2.013  -1.204   1.522  1.00  5.93           C  
ATOM    127  O   LYS A  16      -1.918  -2.380   1.134  1.00  6.41           O  
ATOM    128  CB  LYS A  16      -2.455   0.727  -0.023  1.00  6.48           C  
ATOM    129  CG  LYS A  16      -3.463   1.537  -0.830  1.00  9.11           C  
ATOM    130  CD  LYS A  16      -2.758   2.512  -1.758  1.00 11.77           C  
ATOM    131  CE ALYS A  16      -3.716   3.314  -2.597  0.50 14.92           C  
ATOM    132  CE BLYS A  16      -3.461   3.856  -1.823  0.50 12.86           C  
ATOM    133  NZ ALYS A  16      -4.322   2.523  -3.694  0.50 24.21           N  
ATOM    134  NZ BLYS A  16      -3.692   4.316  -3.224  0.50 11.85           N  
ATOM    135  N   ALA A  17      -1.198  -0.770   2.440  1.00  5.61           N  
ATOM    136  CA  ALA A  17      -0.202  -1.654   3.006  1.00  5.23           C  
ATOM    137  C   ALA A  17      -0.842  -2.795   3.784  1.00  5.60           C  
ATOM    138  O   ALA A  17      -0.393  -3.930   3.762  1.00  6.03           O  
ATOM    139  CB  ALA A  17       0.683  -0.803   3.886  1.00  6.76           C  
ATOM    140  N   SER A  18      -1.883  -2.477   4.526  1.00  5.10           N  
ATOM    141  CA  SER A  18      -2.610  -3.474   5.313  1.00  5.89           C  
ATOM    142  C   SER A  18      -3.139  -4.590   4.414  1.00  6.24           C  
ATOM    143  O   SER A  18      -3.034  -5.773   4.765  1.00  6.88           O  
ATOM    144  CB ASER A  18      -3.723  -2.795   6.105  0.50  7.24           C  
ATOM    145  CB BSER A  18      -3.833  -2.800   5.959  0.50  6.90           C  
ATOM    146  OG ASER A  18      -4.472  -3.741   6.838  0.50  8.33           O  
ATOM    147  OG BSER A  18      -3.466  -2.022   7.079  0.50  8.03           O  
ATOM    148  N   ALA A  19      -3.656  -4.267   3.249  1.00  5.45           N  
ATOM    149  CA  ALA A  19      -4.162  -5.269   2.329  1.00  6.03           C  
ATOM    150  C   ALA A  19      -3.051  -6.223   1.876  1.00  5.81           C  
ATOM    151  O   ALA A  19      -3.312  -7.396   1.638  1.00  6.53           O  
ATOM    152  CB  ALA A  19      -4.799  -4.626   1.104  1.00  8.85           C  
ATOM    153  N   ALA A  20      -1.834  -5.706   1.794  1.00  5.38           N  
ATOM    154  CA  ALA A  20      -0.694  -6.476   1.361  1.00  5.69           C  
ATOM    155  C   ALA A  20       0.185  -6.984   2.490  1.00  4.76           C  
ATOM    156  O   ALA A  20       1.214  -7.613   2.200  1.00  5.76           O  
ATOM    157  CB  ALA A  20       0.158  -5.575   0.472  1.00  5.71           C  
ATOM    158  N   TRP A  21      -0.243  -6.807   3.741  1.00  4.70           N  
ATOM    159  CA  TRP A  21       0.680  -6.982   4.865  1.00  5.03           C  
ATOM    160  C   TRP A  21       1.085  -8.441   5.056  1.00  4.59           C  
ATOM    161  O   TRP A  21       2.128  -8.666   5.700  1.00  6.09           O  
ATOM    162  CB  TRP A  21       0.106  -6.446   6.147  1.00  5.61           C  
ATOM    163  CG  TRP A  21       1.084  -6.048   7.208  1.00  3.65           C  
ATOM    164  CD1 TRP A  21       1.265  -6.661   8.425  1.00  5.49           C  
ATOM    165  CD2 TRP A  21       2.014  -4.954   7.171  1.00  4.65           C  
ATOM    166  NE1 TRP A  21       2.244  -6.011   9.143  1.00  5.09           N  
ATOM    167  CE2 TRP A  21       2.724  -4.957   8.391  1.00  4.21           C  
ATOM    168  CE3 TRP A  21       2.334  -3.968   6.243  1.00  4.78           C  
ATOM    169  CZ2 TRP A  21       3.711  -4.019   8.693  1.00  5.43           C  
ATOM    170  CZ3 TRP A  21       3.303  -3.037   6.523  1.00  6.31           C  
ATOM    171  CH2 TRP A  21       3.988  -3.071   7.749  1.00  5.73           C  
ATOM    172  N   GLY A  22       0.356  -9.421   4.550  1.00  4.91           N  
ATOM    173  CA  GLY A  22       0.803 -10.826   4.662  1.00  6.34           C  
ATOM    174  C   GLY A  22       2.139 -11.059   3.975  1.00  6.61           C  
ATOM    175  O   GLY A  22       2.916 -11.894   4.413  1.00  7.79           O  
ATOM    176  N   THR A  23       2.487 -10.202   3.004  1.00  6.48           N  
ATOM    177  CA  THR A  23       3.798 -10.285   2.387  1.00  6.63           C  
ATOM    178  C   THR A  23       4.614  -9.062   2.769  1.00  6.14           C  
ATOM    179  O   THR A  23       5.834  -9.182   2.969  1.00  6.37           O  
ATOM    180  CB  THR A  23       3.797 -10.433   0.853  1.00  6.72           C  
ATOM    181  OG1 THR A  23       3.357  -9.224   0.243  1.00  8.05           O  
ATOM    182  CG2 THR A  23       2.888 -11.588   0.429  1.00  8.71           C  
ATOM    183  N   ALA A  24       4.007  -7.895   2.829  1.00  5.51           N  
ATOM    184  CA  ALA A  24       4.732  -6.650   3.097  1.00  5.53           C  
ATOM    185  C   ALA A  24       5.213  -6.532   4.525  1.00  6.41           C  
ATOM    186  O   ALA A  24       6.266  -5.953   4.812  1.00  6.66           O  
ATOM    187  CB  ALA A  24       3.879  -5.436   2.730  1.00  7.52           C  
ATOM    188  N   GLY A  25       4.483  -7.072   5.481  1.00  6.27           N  
ATOM    189  CA  GLY A  25       4.906  -6.922   6.862  1.00  5.94           C  
ATOM    190  C   GLY A  25       6.250  -7.595   7.091  1.00  5.58           C  
ATOM    191  O   GLY A  25       7.139  -6.976   7.687  1.00  5.42           O  
ATOM    192  N   PRO A  26       6.432  -8.856   6.667  1.00  5.12           N  
ATOM    193  CA  PRO A  26       7.765  -9.456   6.811  1.00  5.75           C  
ATOM    194  C   PRO A  26       8.838  -8.631   6.135  1.00  5.94           C  
ATOM    195  O   PRO A  26       9.953  -8.540   6.653  1.00  7.04           O  
ATOM    196  CB  PRO A  26       7.572 -10.835   6.169  1.00  7.26           C  
ATOM    197  CG  PRO A  26       6.132 -11.172   6.481  1.00  7.30           C  
ATOM    198  CD  PRO A  26       5.428  -9.825   6.262  1.00  6.21           C  
ATOM    199  N   GLU A  27       8.528  -8.021   5.008  1.00  6.37           N  
ATOM    200  CA  GLU A  27       9.537  -7.178   4.361  1.00  7.93           C  
ATOM    201  C   GLU A  27       9.870  -5.926   5.159  1.00  6.53           C  
ATOM    202  O   GLU A  27      11.030  -5.530   5.268  1.00  7.42           O  
ATOM    203  CB  GLU A  27       9.065  -6.763   2.953  1.00 11.31           C  
ATOM    204  CG  GLU A  27       8.787  -7.985   2.092  1.00 17.54           C  
ATOM    205  CD  GLU A  27       9.942  -8.320   1.176  1.00 22.71           C  
ATOM    206  OE1 GLU A  27      11.066  -8.084   1.709  1.00 28.45           O  
ATOM    207  OE2 GLU A  27       9.618  -9.138   0.265  1.00 29.48           O  
ATOM    208  N   PHE A  28       8.858  -5.304   5.756  1.00  5.82           N  
ATOM    209  CA  PHE A  28       9.103  -4.154   6.596  1.00  5.47           C  
ATOM    210  C   PHE A  28      10.016  -4.566   7.750  1.00  4.94           C  
ATOM    211  O   PHE A  28      10.974  -3.866   8.085  1.00  5.18           O  
ATOM    212  CB  PHE A  28       7.763  -3.606   7.085  1.00  5.43           C  
ATOM    213  CG  PHE A  28       7.954  -2.742   8.328  1.00  5.30           C  
ATOM    214  CD1 PHE A  28       8.496  -1.479   8.218  1.00  5.82           C  
ATOM    215  CD2 PHE A  28       7.614  -3.237   9.574  1.00  5.22           C  
ATOM    216  CE1 PHE A  28       8.690  -0.715   9.371  1.00  7.07           C  
ATOM    217  CE2 PHE A  28       7.811  -2.491  10.744  1.00  6.55           C  
ATOM    218  CZ  PHE A  28       8.370  -1.241  10.610  1.00  6.52           C  
ATOM    219  N   PHE A  29       9.703  -5.669   8.452  1.00  4.81           N  
ATOM    220  CA  PHE A  29      10.554  -6.079   9.570  1.00  5.05           C  
ATOM    221  C   PHE A  29      11.972  -6.329   9.106  1.00  4.72           C  
ATOM    222  O   PHE A  29      12.934  -5.984   9.808  1.00  5.84           O  
ATOM    223  CB  PHE A  29       9.979  -7.299  10.305  1.00  4.82           C  
ATOM    224  CG  PHE A  29       8.951  -6.860  11.363  1.00  5.36           C  
ATOM    225  CD1 PHE A  29       9.381  -6.513  12.634  1.00  6.28           C  
ATOM    226  CD2 PHE A  29       7.595  -6.791  11.076  1.00  5.61           C  
ATOM    227  CE1 PHE A  29       8.456  -6.071  13.578  1.00  6.55           C  
ATOM    228  CE2 PHE A  29       6.676  -6.350  11.997  1.00  5.24           C  
ATOM    229  CZ  PHE A  29       7.114  -6.014  13.252  1.00  5.84           C  
ATOM    230  N   MET A  30      12.164  -6.949   7.931  1.00  5.41           N  
ATOM    231  CA  MET A  30      13.536  -7.172   7.504  1.00  5.79           C  
ATOM    232  C   MET A  30      14.261  -5.835   7.220  1.00  5.40           C  
ATOM    233  O   MET A  30      15.449  -5.684   7.555  1.00  7.07           O  
ATOM    234  CB  MET A  30      13.613  -8.067   6.272  1.00  6.51           C  
ATOM    235  CG  MET A  30      13.097  -9.452   6.530  1.00  6.35           C  
ATOM    236  SD  MET A  30      13.836 -10.345   7.896  1.00  8.65           S  
ATOM    237  CE  MET A  30      15.557 -10.382   7.384  1.00 14.68           C  
ATOM    238  N   ALA A  31      13.545  -4.853   6.713  1.00  5.95           N  
ATOM    239  CA  ALA A  31      14.151  -3.531   6.477  1.00  7.03           C  
ATOM    240  C   ALA A  31      14.536  -2.908   7.810  1.00  6.71           C  
ATOM    241  O   ALA A  31      15.627  -2.332   7.967  1.00  8.03           O  
ATOM    242  CB  ALA A  31      13.236  -2.596   5.701  1.00  9.47           C  
ATOM    243  N   LEU A  32      13.660  -3.063   8.802  1.00  6.19           N  
ATOM    244  CA  LEU A  32      13.920  -2.557  10.146  1.00  6.02           C  
ATOM    245  C   LEU A  32      15.140  -3.212  10.783  1.00  5.90           C  
ATOM    246  O   LEU A  32      16.043  -2.573  11.349  1.00  6.17           O  
ATOM    247  CB  LEU A  32      12.666  -2.800  11.001  1.00  6.18           C  
ATOM    248  CG  LEU A  32      12.755  -2.403  12.467  1.00  7.07           C  
ATOM    249  CD1 LEU A  32      13.236  -0.969  12.610  1.00  8.12           C  
ATOM    250  CD2 LEU A  32      11.407  -2.560  13.154  1.00  7.57           C  
ATOM    251  N   PHE A  33      15.144  -4.547  10.687  1.00  6.20           N  
ATOM    252  CA  PHE A  33      16.257  -5.300  11.242  1.00  6.66           C  
ATOM    253  C   PHE A  33      17.567  -4.997  10.541  1.00  7.73           C  
ATOM    254  O   PHE A  33      18.645  -4.937  11.156  1.00  8.28           O  
ATOM    255  CB  PHE A  33      15.976  -6.804  11.155  1.00  7.86           C  
ATOM    256  CG  PHE A  33      14.808  -7.265  12.001  1.00  6.82           C  
ATOM    257  CD1 PHE A  33      14.281  -6.551  13.050  1.00  6.87           C  
ATOM    258  CD2 PHE A  33      14.202  -8.486  11.712  1.00  7.13           C  
ATOM    259  CE1 PHE A  33      13.196  -7.006  13.782  1.00  7.24           C  
ATOM    260  CE2 PHE A  33      13.117  -8.939  12.421  1.00  7.07           C  
ATOM    261  CZ  PHE A  33      12.599  -8.189  13.467  1.00  7.25           C  
ATOM    262  N   ASP A  34      17.554  -4.878   9.218  1.00  7.76           N  
ATOM    263  CA  ASP A  34      18.768  -4.524   8.479  1.00  9.33           C  
ATOM    264  C   ASP A  34      19.256  -3.125   8.816  1.00  8.78           C  
ATOM    265  O   ASP A  34      20.473  -2.904   8.902  1.00 11.21           O  
ATOM    266  CB  ASP A  34      18.504  -4.632   6.984  1.00 12.08           C  
ATOM    267  CG  ASP A  34      18.469  -6.042   6.396  1.00 14.55           C  
ATOM    268  OD1 ASP A  34      18.954  -7.024   7.033  1.00 18.37           O  
ATOM    269  OD2 ASP A  34      17.993  -6.162   5.231  1.00 18.71           O  
ATOM    270  N   ALA A  35      18.389  -2.176   9.107  1.00  8.42           N  
ATOM    271  CA  ALA A  35      18.789  -0.797   9.438  1.00  9.88           C  
ATOM    272  C   ALA A  35      19.230  -0.669  10.885  1.00  8.91           C  
ATOM    273  O   ALA A  35      19.965   0.266  11.231  1.00 10.87           O  
ATOM    274  CB  ALA A  35      17.676   0.179   9.124  1.00 10.47           C  
ATOM    275  N   HIS A  36      18.681  -1.482  11.775  1.00  8.56           N  
ATOM    276  CA  HIS A  36      18.871  -1.359  13.224  1.00  8.13           C  
ATOM    277  C   HIS A  36      19.063  -2.740  13.873  1.00  8.28           C  
ATOM    278  O   HIS A  36      18.106  -3.395  14.303  1.00  7.42           O  
ATOM    279  CB  HIS A  36      17.709  -0.607  13.897  1.00  7.79           C  
ATOM    280  CG  HIS A  36      17.483   0.736  13.270  1.00  9.01           C  
ATOM    281  ND1 HIS A  36      18.274   1.823  13.564  1.00  9.61           N  
ATOM    282  CD2 HIS A  36      16.632   1.139  12.308  1.00 10.21           C  
ATOM    283  CE1 HIS A  36      17.865   2.854  12.841  1.00  9.63           C  
ATOM    284  NE2 HIS A  36      16.864   2.462  12.079  1.00  9.56           N  
ATOM    285  N   ASP A  37      20.333  -3.203  13.902  1.00  8.95           N  
ATOM    286  CA  ASP A  37      20.591  -4.532  14.438  1.00  9.20           C  
ATOM    287  C   ASP A  37      20.130  -4.634  15.891  1.00  9.63           C  
ATOM    288  O   ASP A  37      19.743  -5.740  16.320  1.00  8.99           O  
ATOM    289  CB  ASP A  37      22.076  -4.864  14.278  1.00 12.73           C  
ATOM    290  CG  ASP A  37      22.372  -6.340  14.447  1.00 15.76           C  
ATOM    291  OD1 ASP A  37      21.864  -7.168  13.673  1.00 16.56           O  
ATOM    292  OD2 ASP A  37      23.023  -6.640  15.473  1.00 26.96           O  
ATOM    293  N   ASP A  38      20.158  -3.525  16.646  1.00  8.29           N  
ATOM    294  CA  ASP A  38      19.750  -3.581  18.037  1.00  7.04           C  
ATOM    295  C   ASP A  38      18.253  -3.810  18.216  1.00  6.30           C  
ATOM    296  O   ASP A  38      17.844  -4.346  19.245  1.00  7.32           O  
ATOM    297  CB  ASP A  38      20.120  -2.267  18.752  1.00  7.87           C  
ATOM    298  CG  ASP A  38      19.664  -1.033  17.999  1.00  7.40           C  
ATOM    299  OD1 ASP A  38      20.228  -0.851  16.897  1.00 11.84           O  
ATOM    300  OD2 ASP A  38      18.742  -0.317  18.421  1.00  8.44           O  
ATOM    301  N   VAL A  39      17.495  -3.401  17.182  1.00  6.65           N  
ATOM    302  CA  VAL A  39      16.063  -3.713  17.167  1.00  6.18           C  
ATOM    303  C   VAL A  39      15.881  -5.212  16.973  1.00  5.92           C  
ATOM    304  O   VAL A  39      15.180  -5.895  17.713  1.00  6.52           O  
ATOM    305  CB  VAL A  39      15.363  -2.868  16.101  1.00  6.01           C  
ATOM    306  CG1 VAL A  39      13.948  -3.389  15.911  1.00  6.83           C  
ATOM    307  CG2 VAL A  39      15.368  -1.403  16.519  1.00  7.59           C  
ATOM    308  N   PHE A  40      16.616  -5.805  16.048  1.00  6.32           N  
ATOM    309  CA  PHE A  40      16.530  -7.240  15.845  1.00  7.05           C  
ATOM    310  C   PHE A  40      16.926  -7.994  17.106  1.00  6.82           C  
ATOM    311  O   PHE A  40      16.248  -8.963  17.495  1.00  7.50           O  
ATOM    312  CB  PHE A  40      17.463  -7.699  14.724  1.00  7.61           C  
ATOM    313  CG  PHE A  40      17.408  -9.203  14.544  1.00  7.05           C  
ATOM    314  CD1 PHE A  40      16.243  -9.799  14.082  1.00  7.74           C  
ATOM    315  CD2 PHE A  40      18.489  -9.994  14.870  1.00  8.87           C  
ATOM    316  CE1 PHE A  40      16.198 -11.177  13.958  1.00  8.76           C  
ATOM    317  CE2 PHE A  40      18.430 -11.373  14.707  1.00  9.92           C  
ATOM    318  CZ  PHE A  40      17.282 -11.977  14.247  1.00  9.05           C  
ATOM    319  N   ALA A  41      17.867  -7.449  17.862  1.00  7.21           N  
ATOM    320  CA  ALA A  41      18.309  -8.138  19.081  1.00  8.00           C  
ATOM    321  C   ALA A  41      17.197  -8.364  20.102  1.00  8.54           C  
ATOM    322  O   ALA A  41      17.209  -9.365  20.844  1.00  8.20           O  
ATOM    323  CB  ALA A  41      19.475  -7.375  19.715  1.00 10.52           C  
ATOM    324  N   LYS A  42      16.275  -7.414  20.204  1.00  8.65           N  
ATOM    325  CA  LYS A  42      15.169  -7.507  21.173  1.00  8.28           C  
ATOM    326  C   LYS A  42      14.168  -8.581  20.764  1.00  7.28           C  
ATOM    327  O   LYS A  42      13.333  -8.910  21.609  1.00  8.65           O  
ATOM    328  CB  LYS A  42      14.482  -6.137  21.291  1.00  8.27           C  
ATOM    329  CG  LYS A  42      15.299  -5.124  22.100  1.00  9.54           C  
ATOM    330  CD  LYS A  42      15.187  -5.393  23.592  1.00  9.61           C  
ATOM    331  CE ALYS A  42      16.065  -4.471  24.415  0.50 12.33           C  
ATOM    332  CE BLYS A  42      15.811  -4.299  24.436  0.50 10.81           C  
ATOM    333  NZ ALYS A  42      17.519  -4.704  24.136  0.50 15.81           N  
ATOM    334  NZ BLYS A  42      16.095  -4.775  25.822  0.50  9.89           N  
ATOM    335  N   PHE A  43      14.272  -9.097  19.533  1.00  6.28           N  
ATOM    336  CA  PHE A  43      13.383 -10.157  19.057  1.00  7.27           C  
ATOM    337  C   PHE A  43      14.070 -11.505  19.159  1.00  8.28           C  
ATOM    338  O   PHE A  43      13.520 -12.527  18.705  1.00  8.14           O  
ATOM    339  CB  PHE A  43      12.914  -9.906  17.618  1.00  7.25           C  
ATOM    340  CG  PHE A  43      11.874  -8.792  17.476  1.00  7.31           C  
ATOM    341  CD1 PHE A  43      10.511  -9.018  17.656  1.00  7.88           C  
ATOM    342  CD2 PHE A  43      12.274  -7.516  17.130  1.00  6.88           C  
ATOM    343  CE1 PHE A  43       9.593  -7.987  17.532  1.00  7.69           C  
ATOM    344  CE2 PHE A  43      11.362  -6.490  17.016  1.00  7.19           C  
ATOM    345  CZ  PHE A  43      10.017  -6.724  17.169  1.00  7.80           C  
ATOM    346  N   SER A  44      15.204 -11.585  19.843  1.00 11.34           N  
ATOM    347  CA  SER A  44      15.943 -12.853  19.827  1.00 11.37           C  
ATOM    348  C   SER A  44      15.279 -13.910  20.689  1.00 12.34           C  
ATOM    349  O   SER A  44      15.281 -15.130  20.446  1.00 13.44           O  
ATOM    350  CB  SER A  44      17.374 -12.582  20.284  1.00 14.28           C  
ATOM    351  OG  SER A  44      17.282 -12.247  21.694  1.00 23.70           O  
ATOM    352  N   GLY A  45      14.395 -13.509  21.594  1.00 12.74           N  
ATOM    353  CA  GLY A  45      13.615 -14.563  22.216  1.00 13.29           C  
ATOM    354  C   GLY A  45      12.517 -15.135  21.344  1.00 10.57           C  
ATOM    355  O   GLY A  45      12.378 -16.351  21.191  1.00 11.48           O  
ATOM    356  N   LEU A  46      11.792 -14.250  20.672  1.00  9.86           N  
ATOM    357  CA  LEU A  46      10.745 -14.647  19.749  1.00  8.13           C  
ATOM    358  C   LEU A  46      11.306 -15.608  18.711  1.00  7.42           C  
ATOM    359  O   LEU A  46      10.699 -16.616  18.373  1.00  8.55           O  
ATOM    360  CB  LEU A  46      10.167 -13.425  19.044  1.00  7.38           C  
ATOM    361  CG  LEU A  46       9.202 -13.720  17.901  1.00  9.84           C  
ATOM    362  CD1 LEU A  46       8.009 -14.470  18.465  1.00 10.78           C  
ATOM    363  CD2 LEU A  46       8.839 -12.431  17.169  1.00 10.19           C  
ATOM    364  N   PHE A  47      12.405 -15.237  18.081  1.00  6.27           N  
ATOM    365  CA  PHE A  47      13.008 -15.993  17.009  1.00  6.69           C  
ATOM    366  C   PHE A  47      13.968 -17.093  17.489  1.00  7.78           C  
ATOM    367  O   PHE A  47      14.626 -17.732  16.652  1.00  8.39           O  
ATOM    368  CB  PHE A  47      13.760 -15.070  16.035  1.00  6.85           C  
ATOM    369  CG  PHE A  47      12.830 -14.146  15.258  1.00  5.95           C  
ATOM    370  CD1 PHE A  47      11.782 -14.616  14.485  1.00  6.73           C  
ATOM    371  CD2 PHE A  47      12.998 -12.788  15.322  1.00  6.56           C  
ATOM    372  CE1 PHE A  47      10.913 -13.820  13.781  1.00  6.30           C  
ATOM    373  CE2 PHE A  47      12.153 -11.952  14.601  1.00  7.59           C  
ATOM    374  CZ  PHE A  47      11.111 -12.448  13.837  1.00  7.57           C  
ATOM    375  N   SER A  48      13.944 -17.378  18.767  1.00  8.19           N  
ATOM    376  CA  SER A  48      14.680 -18.473  19.386  1.00  8.80           C  
ATOM    377  C   SER A  48      16.136 -18.493  18.892  1.00  8.53           C  
ATOM    378  O   SER A  48      16.820 -19.471  18.579  1.00  9.11           O  
ATOM    379  CB  SER A  48      13.989 -19.825  19.198  1.00 10.57           C  
ATOM    380  OG  SER A  48      12.582 -19.841  19.572  1.00 20.19           O  
ATOM    381  N   GLY A  49      16.761 -17.309  18.910  1.00  7.98           N  
ATOM    382  CA  GLY A  49      18.197 -17.223  18.720  1.00  7.79           C  
ATOM    383  C   GLY A  49      18.625 -17.196  17.282  1.00  7.48           C  
ATOM    384  O   GLY A  49      19.828 -17.191  16.980  1.00  8.55           O  
ATOM    385  N   ALA A  50      17.714 -17.356  16.337  1.00  7.35           N  
ATOM    386  CA  ALA A  50      18.055 -17.525  14.933  1.00  7.00           C  
ATOM    387  C   ALA A  50      18.716 -16.263  14.382  1.00  8.11           C  
ATOM    388  O   ALA A  50      18.425 -15.163  14.814  1.00  8.85           O  
ATOM    389  CB  ALA A  50      16.793 -17.845  14.145  1.00  8.03           C  
ATOM    390  N   ALA A  51      19.552 -16.461  13.363  1.00  7.40           N  
ATOM    391  CA  ALA A  51      20.200 -15.355  12.682  1.00  7.72           C  
ATOM    392  C   ALA A  51      19.166 -14.601  11.831  1.00  7.73           C  
ATOM    393  O   ALA A  51      18.222 -15.163  11.258  1.00  9.32           O  
ATOM    394  CB  ALA A  51      21.358 -15.878  11.857  1.00  9.00           C  
ATOM    395  N   LYS A  52      19.386 -13.296  11.705  1.00  8.70           N  
ATOM    396  CA  LYS A  52      18.500 -12.370  11.019  1.00 10.55           C  
ATOM    397  C   LYS A  52      18.121 -12.834   9.626  1.00 10.91           C  
ATOM    398  O   LYS A  52      16.995 -12.793   9.122  1.00 10.44           O  
ATOM    399  CB  LYS A  52      19.247 -11.019  10.983  1.00 12.59           C  
ATOM    400  CG  LYS A  52      18.528  -9.867  10.367  1.00 13.26           C  
ATOM    401  CD  LYS A  52      19.350  -8.586  10.156  1.00 14.48           C  
ATOM    402  CE  LYS A  52      20.158  -8.079  11.331  1.00 17.26           C  
ATOM    403  NZ  LYS A  52      20.870  -6.747  11.260  1.00 16.16           N  
ATOM    404  N   GLY A  53      19.129 -13.383   8.931  1.00 11.80           N  
ATOM    405  CA  GLY A  53      18.925 -13.809   7.565  1.00 14.68           C  
ATOM    406  C   GLY A  53      18.063 -15.035   7.390  1.00 14.77           C  
ATOM    407  O   GLY A  53      17.772 -15.450   6.262  1.00 21.11           O  
ATOM    408  N   THR A  54      17.569 -15.607   8.477  1.00 12.98           N  
ATOM    409  CA  THR A  54      16.701 -16.761   8.415  1.00 10.78           C  
ATOM    410  C   THR A  54      15.270 -16.496   8.838  1.00  9.44           C  
ATOM    411  O   THR A  54      14.456 -17.421   8.763  1.00 11.58           O  
ATOM    412  CB  THR A  54      17.302 -17.908   9.286  1.00 12.17           C  
ATOM    413  OG1 THR A  54      17.111 -17.580  10.656  1.00 10.95           O  
ATOM    414  CG2 THR A  54      18.784 -18.044   8.968  1.00 16.67           C  
ATOM    415  N   VAL A  55      14.923 -15.322   9.339  1.00  8.40           N  
ATOM    416  CA  VAL A  55      13.678 -15.195  10.077  1.00  6.92           C  
ATOM    417  C   VAL A  55      12.494 -14.795   9.213  1.00  7.03           C  
ATOM    418  O   VAL A  55      11.353 -14.872   9.693  1.00  6.92           O  
ATOM    419  CB  VAL A  55      13.797 -14.208  11.270  1.00  6.76           C  
ATOM    420  CG1 VAL A  55      14.830 -14.718  12.274  1.00  7.39           C  
ATOM    421  CG2 VAL A  55      14.145 -12.794  10.859  1.00  5.49           C  
ATOM    422  N   LYS A  56      12.697 -14.300   8.002  1.00  7.07           N  
ATOM    423  CA  LYS A  56      11.610 -13.668   7.257  1.00  8.60           C  
ATOM    424  C   LYS A  56      10.380 -14.554   7.102  1.00  8.90           C  
ATOM    425  O   LYS A  56       9.244 -14.048   7.132  1.00  9.83           O  
ATOM    426  CB  LYS A  56      12.092 -13.242   5.867  1.00  9.61           C  
ATOM    427  CG  LYS A  56      11.076 -12.399   5.097  1.00 11.96           C  
ATOM    428  CD  LYS A  56      11.767 -12.013   3.771  1.00 16.51           C  
ATOM    429  CE  LYS A  56      10.825 -11.241   2.890  1.00 21.29           C  
ATOM    430  NZ  LYS A  56      11.293 -11.197   1.491  1.00 28.74           N  
ATOM    431  N   ASN A  57      10.605 -15.812   6.722  1.00  8.86           N  
ATOM    432  CA  ASN A  57       9.507 -16.729   6.418  1.00  9.98           C  
ATOM    433  C   ASN A  57       9.178 -17.684   7.558  1.00  8.65           C  
ATOM    434  O   ASN A  57       8.464 -18.655   7.339  1.00 13.32           O  
ATOM    435  CB  ASN A  57       9.890 -17.490   5.152  1.00 13.97           C  
ATOM    436  CG  ASN A  57      10.056 -16.519   3.978  1.00 19.54           C  
ATOM    437  OD1 ASN A  57      10.964 -16.698   3.133  1.00 28.00           O  
ATOM    438  ND2 ASN A  57       9.060 -15.671   3.697  1.00 24.06           N  
ATOM    439  N   THR A  58       9.429 -17.254   8.789  1.00  6.53           N  
ATOM    440  CA  THR A  58       9.048 -18.043   9.947  1.00  6.89           C  
ATOM    441  C   THR A  58       7.605 -17.792  10.387  1.00  6.27           C  
ATOM    442  O   THR A  58       7.019 -16.726  10.186  1.00  6.98           O  
ATOM    443  CB  THR A  58       9.971 -17.754  11.150  1.00  7.82           C  
ATOM    444  OG1 THR A  58       9.966 -16.383  11.523  1.00  7.45           O  
ATOM    445  CG2 THR A  58      11.403 -18.085  10.791  1.00  8.44           C  
ATOM    446  N   PRO A  59       7.025 -18.750  11.122  1.00  6.71           N  
ATOM    447  CA  PRO A  59       5.708 -18.499  11.685  1.00  6.78           C  
ATOM    448  C   PRO A  59       5.720 -17.346  12.689  1.00  6.31           C  
ATOM    449  O   PRO A  59       4.731 -16.600  12.775  1.00  6.47           O  
ATOM    450  CB  PRO A  59       5.417 -19.816  12.402  1.00  7.23           C  
ATOM    451  CG  PRO A  59       6.269 -20.872  11.773  1.00  9.22           C  
ATOM    452  CD  PRO A  59       7.501 -20.134  11.307  1.00  8.52           C  
ATOM    453  N   GLU A  60       6.824 -17.177  13.426  1.00  5.64           N  
ATOM    454  CA  GLU A  60       6.931 -16.090  14.404  1.00  5.58           C  
ATOM    455  C   GLU A  60       6.873 -14.728  13.713  1.00  5.45           C  
ATOM    456  O   GLU A  60       6.291 -13.755  14.191  1.00  6.03           O  
ATOM    457  CB  GLU A  60       8.216 -16.254  15.179  1.00  7.20           C  
ATOM    458  CG  GLU A  60       8.376 -17.430  16.114  1.00  8.46           C  
ATOM    459  CD  GLU A  60       8.652 -18.785  15.520  1.00  9.27           C  
ATOM    460  OE1 GLU A  60       8.909 -18.936  14.309  1.00  8.74           O  
ATOM    461  OE2 GLU A  60       8.632 -19.750  16.331  1.00 14.98           O  
ATOM    462  N   MET A  61       7.520 -14.610  12.572  1.00  5.23           N  
ATOM    463  CA  MET A  61       7.480 -13.375  11.812  1.00  5.29           C  
ATOM    464  C   MET A  61       6.062 -13.086  11.321  1.00  5.67           C  
ATOM    465  O   MET A  61       5.627 -11.938  11.349  1.00  5.81           O  
ATOM    466  CB  MET A  61       8.465 -13.407  10.624  1.00  6.14           C  
ATOM    467  CG  MET A  61       8.381 -12.229   9.674  1.00  6.85           C  
ATOM    468  SD  MET A  61       8.956 -10.676  10.473  1.00  7.17           S  
ATOM    469  CE  MET A  61      10.657 -10.733   9.914  1.00 12.26           C  
ATOM    470  N   ALA A  62       5.337 -14.099  10.822  1.00  5.33           N  
ATOM    471  CA  ALA A  62       3.968 -13.866  10.367  1.00  5.05           C  
ATOM    472  C   ALA A  62       3.111 -13.379  11.519  1.00  6.06           C  
ATOM    473  O   ALA A  62       2.321 -12.448  11.380  1.00  6.04           O  
ATOM    474  CB  ALA A  62       3.411 -15.152   9.791  1.00  6.81           C  
ATOM    475  N   ALA A  63       3.304 -13.961  12.704  1.00  6.29           N  
ATOM    476  CA  ALA A  63       2.549 -13.499  13.884  1.00  5.42           C  
ATOM    477  C   ALA A  63       2.929 -12.086  14.268  1.00  5.64           C  
ATOM    478  O   ALA A  63       2.073 -11.248  14.602  1.00  6.20           O  
ATOM    479  CB  ALA A  63       2.754 -14.462  15.035  1.00  6.76           C  
ATOM    480  N   GLN A  64       4.234 -11.802  14.219  1.00  4.83           N  
ATOM    481  CA  GLN A  64       4.695 -10.450  14.633  1.00  5.68           C  
ATOM    482  C   GLN A  64       4.184  -9.381  13.671  1.00  4.78           C  
ATOM    483  O   GLN A  64       3.780  -8.289  14.089  1.00  5.43           O  
ATOM    484  CB  GLN A  64       6.224 -10.377  14.767  1.00  6.54           C  
ATOM    485  CG  GLN A  64       6.689  -9.204  15.635  1.00  7.12           C  
ATOM    486  CD  GLN A  64       6.097  -9.204  17.022  1.00  7.20           C  
ATOM    487  OE1 GLN A  64       5.720  -8.137  17.582  1.00 11.09           O  
ATOM    488  NE2 GLN A  64       5.934 -10.377  17.604  1.00  7.76           N  
ATOM    489  N   ALA A  65       4.186  -9.674  12.374  1.00  5.03           N  
ATOM    490  CA  ALA A  65       3.654  -8.723  11.402  1.00  5.54           C  
ATOM    491  C   ALA A  65       2.181  -8.437  11.724  1.00  4.96           C  
ATOM    492  O   ALA A  65       1.736  -7.280  11.674  1.00  5.37           O  
ATOM    493  CB  ALA A  65       3.836  -9.247   9.991  1.00  6.55           C  
ATOM    494  N   GLN A  66       1.424  -9.460  12.128  1.00  5.13           N  
ATOM    495  CA  GLN A  66       0.012  -9.264  12.506  1.00  6.22           C  
ATOM    496  C   GLN A  66      -0.123  -8.409  13.749  1.00  5.32           C  
ATOM    497  O   GLN A  66      -1.015  -7.555  13.851  1.00  5.79           O  
ATOM    498  CB  GLN A  66      -0.619 -10.637  12.696  1.00  7.42           C  
ATOM    499  CG  GLN A  66      -1.972 -10.793  13.337  1.00 11.10           C  
ATOM    500  CD  GLN A  66      -2.426 -12.238  13.526  1.00 13.13           C  
ATOM    501  OE1 GLN A  66      -2.115 -12.907  14.512  1.00 14.74           O  
ATOM    502  NE2 GLN A  66      -3.271 -12.673  12.577  1.00 15.93           N  
ATOM    503  N   SER A  67       0.746  -8.644  14.727  1.00  5.42           N  
ATOM    504  CA  SER A  67       0.698  -7.855  15.952  1.00  6.28           C  
ATOM    505  C   SER A  67       0.944  -6.392  15.673  1.00  5.70           C  
ATOM    506  O   SER A  67       0.227  -5.492  16.144  1.00  5.46           O  
ATOM    507  CB  SER A  67       1.782  -8.366  16.911  1.00  7.60           C  
ATOM    508  OG  SER A  67       1.439  -9.693  17.305  1.00  8.57           O  
ATOM    509  N   PHE A  68       2.007  -6.105  14.944  1.00  5.14           N  
ATOM    510  CA  PHE A  68       2.360  -4.721  14.598  1.00  5.85           C  
ATOM    511  C   PHE A  68       1.225  -4.032  13.873  1.00  4.78           C  
ATOM    512  O   PHE A  68       0.825  -2.912  14.191  1.00  5.49           O  
ATOM    513  CB  PHE A  68       3.619  -4.789  13.750  1.00  6.35           C  
ATOM    514  CG  PHE A  68       4.228  -3.447  13.369  1.00  5.13           C  
ATOM    515  CD1 PHE A  68       3.799  -2.780  12.242  1.00  5.15           C  
ATOM    516  CD2 PHE A  68       5.252  -2.890  14.137  1.00  5.86           C  
ATOM    517  CE1 PHE A  68       4.330  -1.575  11.837  1.00  7.12           C  
ATOM    518  CE2 PHE A  68       5.802  -1.672  13.764  1.00  6.82           C  
ATOM    519  CZ  PHE A  68       5.346  -1.051  12.613  1.00  7.51           C  
ATOM    520  N   LYS A  69       0.654  -4.699  12.880  1.00  4.48           N  
ATOM    521  CA  LYS A  69      -0.425  -4.140  12.097  1.00  5.26           C  
ATOM    522  C   LYS A  69      -1.622  -3.779  12.943  1.00  5.59           C  
ATOM    523  O   LYS A  69      -2.284  -2.781  12.655  1.00  5.33           O  
ATOM    524  CB  LYS A  69      -0.824  -5.115  10.985  1.00  7.17           C  
ATOM    525  CG  LYS A  69      -2.145  -4.882  10.304  1.00  6.59           C  
ATOM    526  CD  LYS A  69      -2.348  -5.867   9.138  1.00  8.27           C  
ATOM    527  CE  LYS A  69      -3.781  -5.975   8.678  1.00  9.64           C  
ATOM    528  NZ  LYS A  69      -3.997  -6.714   7.406  1.00  9.67           N  
ATOM    529  N   GLY A  70      -1.979  -4.644  13.879  1.00  4.91           N  
ATOM    530  CA  GLY A  70      -3.183  -4.359  14.627  1.00  5.54           C  
ATOM    531  C   GLY A  70      -3.133  -3.057  15.379  1.00  4.74           C  
ATOM    532  O   GLY A  70      -4.150  -2.331  15.457  1.00  6.67           O  
ATOM    533  N   LEU A  71      -1.974  -2.697  15.921  1.00  4.76           N  
ATOM    534  CA  LEU A  71      -1.841  -1.433  16.640  1.00  4.72           C  
ATOM    535  C   LEU A  71      -1.745  -0.249  15.693  1.00  4.42           C  
ATOM    536  O   LEU A  71      -2.422   0.754  15.898  1.00  6.03           O  
ATOM    537  CB  LEU A  71      -0.613  -1.457  17.535  1.00  5.55           C  
ATOM    538  CG  LEU A  71      -0.324  -0.214  18.384  1.00  6.31           C  
ATOM    539  CD1 LEU A  71      -1.552   0.261  19.131  1.00  7.89           C  
ATOM    540  CD2 LEU A  71       0.829  -0.515  19.353  1.00  7.71           C  
ATOM    541  N   VAL A  72      -1.004  -0.370  14.596  1.00  4.84           N  
ATOM    542  CA  VAL A  72      -0.969   0.733  13.632  1.00  5.15           C  
ATOM    543  C   VAL A  72      -2.363   0.979  13.081  1.00  5.72           C  
ATOM    544  O   VAL A  72      -2.763   2.146  12.961  1.00  6.68           O  
ATOM    545  CB  VAL A  72       0.032   0.469  12.487  1.00  4.69           C  
ATOM    546  CG1 VAL A  72      -0.071   1.550  11.429  1.00  6.69           C  
ATOM    547  CG2 VAL A  72       1.472   0.367  13.021  1.00  5.66           C  
ATOM    548  N   SER A  73      -3.153  -0.066  12.816  1.00  5.95           N  
ATOM    549  CA  SER A  73      -4.538   0.170  12.342  1.00  6.38           C  
ATOM    550  C   SER A  73      -5.379   0.951  13.357  1.00  5.65           C  
ATOM    551  O   SER A  73      -6.177   1.811  13.003  1.00  6.43           O  
ATOM    552  CB  SER A  73      -5.174  -1.165  12.026  1.00  6.17           C  
ATOM    553  OG  SER A  73      -4.575  -1.759  10.873  1.00  7.93           O  
ATOM    554  N   ASN A  74      -5.194   0.598  14.649  1.00  5.52           N  
ATOM    555  CA  ASN A  74      -5.939   1.338  15.677  1.00  6.86           C  
ATOM    556  C   ASN A  74      -5.555   2.800  15.751  1.00  6.57           C  
ATOM    557  O   ASN A  74      -6.404   3.698  15.740  1.00  8.84           O  
ATOM    558  CB  ASN A  74      -5.777   0.680  17.055  1.00 10.07           C  
ATOM    559  CG  ASN A  74      -6.780   1.293  18.020  1.00 14.14           C  
ATOM    560  OD1 ASN A  74      -6.685   2.504  18.283  1.00 22.55           O  
ATOM    561  ND2 ASN A  74      -7.500   0.504  18.821  1.00 26.25           N  
ATOM    562  N   TRP A  75      -4.261   3.086  15.667  1.00  6.58           N  
ATOM    563  CA  TRP A  75      -3.829   4.494  15.635  1.00  6.02           C  
ATOM    564  C   TRP A  75      -4.418   5.255  14.462  1.00  6.33           C  
ATOM    565  O   TRP A  75      -4.967   6.349  14.550  1.00  5.82           O  
ATOM    566  CB  TRP A  75      -2.317   4.504  15.630  1.00  6.47           C  
ATOM    567  CG  TRP A  75      -1.635   4.274  16.946  1.00  5.73           C  
ATOM    568  CD1 TRP A  75      -2.075   4.489  18.219  1.00  5.75           C  
ATOM    569  CD2 TRP A  75      -0.292   3.735  17.050  1.00  5.65           C  
ATOM    570  NE1 TRP A  75      -1.112   4.131  19.148  1.00  6.53           N  
ATOM    571  CE2 TRP A  75      -0.013   3.671  18.440  1.00  5.97           C  
ATOM    572  CE3 TRP A  75       0.663   3.311  16.127  1.00  5.41           C  
ATOM    573  CZ2 TRP A  75       1.206   3.202  18.905  1.00  5.99           C  
ATOM    574  CZ3 TRP A  75       1.873   2.851  16.604  1.00  6.37           C  
ATOM    575  CH2 TRP A  75       2.111   2.807  17.982  1.00  7.07           C  
ATOM    576  N   VAL A  76      -4.247   4.708  13.283  1.00  6.94           N  
ATOM    577  CA  VAL A  76      -4.583   5.398  12.049  1.00  8.30           C  
ATOM    578  C   VAL A  76      -6.074   5.594  11.879  1.00  7.70           C  
ATOM    579  O   VAL A  76      -6.563   6.528  11.218  1.00  8.89           O  
ATOM    580  CB AVAL A  76      -3.975   4.537  10.909  0.50 10.90           C  
ATOM    581  CB BVAL A  76      -3.802   4.822  10.876  0.50 10.58           C  
ATOM    582  CG1AVAL A  76      -4.703   4.697   9.620  0.50 14.04           C  
ATOM    583  CG1BVAL A  76      -2.383   4.489  11.351  0.50 11.37           C  
ATOM    584  CG2AVAL A  76      -2.483   4.843  10.769  0.50 12.44           C  
ATOM    585  CG2BVAL A  76      -4.473   3.581  10.329  0.50 10.97           C  
ATOM    586  N   ASP A  77      -6.875   4.787  12.591  1.00  6.72           N  
ATOM    587  CA  ASP A  77      -8.319   4.938  12.618  1.00  8.08           C  
ATOM    588  C   ASP A  77      -8.774   5.994  13.637  1.00  8.37           C  
ATOM    589  O   ASP A  77      -9.969   6.323  13.678  1.00 10.55           O  
ATOM    590  CB  ASP A  77      -9.020   3.610  12.913  1.00 11.00           C  
ATOM    591  CG  ASP A  77      -8.871   2.530  11.885  1.00 14.05           C  
ATOM    592  OD1 ASP A  77      -8.712   2.855  10.700  1.00 24.08           O  
ATOM    593  OD2 ASP A  77      -9.300   1.374  12.118  1.00 22.26           O  
ATOM    594  N   ASN A  78      -7.841   6.552  14.413  1.00  8.05           N  
ATOM    595  CA  ASN A  78      -8.235   7.503  15.467  1.00  7.92           C  
ATOM    596  C   ASN A  78      -7.449   8.790  15.451  1.00  6.67           C  
ATOM    597  O   ASN A  78      -7.173   9.361  16.515  1.00  6.91           O  
ATOM    598  CB  ASN A  78      -8.058   6.814  16.844  1.00  8.69           C  
ATOM    599  CG  ASN A  78      -9.168   5.813  17.075  1.00  9.11           C  
ATOM    600  OD1 ASN A  78     -10.289   6.166  17.416  1.00 14.96           O  
ATOM    601  ND2 ASN A  78      -8.873   4.556  16.767  1.00 10.06           N  
ATOM    602  N   LEU A  79      -7.056   9.261  14.281  1.00  6.72           N  
ATOM    603  CA  LEU A  79      -6.133  10.389  14.194  1.00  6.41           C  
ATOM    604  C   LEU A  79      -6.720  11.739  14.552  1.00  6.70           C  
ATOM    605  O   LEU A  79      -5.975  12.705  14.697  1.00  8.30           O  
ATOM    606  CB  LEU A  79      -5.532  10.429  12.790  1.00  7.41           C  
ATOM    607  CG  LEU A  79      -4.605   9.255  12.404  1.00  7.50           C  
ATOM    608  CD1 LEU A  79      -4.177   9.440  10.962  1.00  9.35           C  
ATOM    609  CD2 LEU A  79      -3.421   9.105  13.351  1.00  7.52           C  
ATOM    610  N   ASP A  80      -8.022  11.820  14.804  1.00  6.84           N  
ATOM    611  CA  ASP A  80      -8.611  13.033  15.349  1.00  6.53           C  
ATOM    612  C   ASP A  80      -8.938  12.916  16.833  1.00  6.58           C  
ATOM    613  O   ASP A  80      -9.621  13.783  17.407  1.00  7.75           O  
ATOM    614  CB  ASP A  80      -9.892  13.361  14.601  1.00  8.44           C  
ATOM    615  CG  ASP A  80      -9.720  13.678  13.144  1.00  8.76           C  
ATOM    616  OD1 ASP A  80      -8.602  13.953  12.664  1.00  8.95           O  
ATOM    617  OD2 ASP A  80     -10.749  13.692  12.448  1.00 10.08           O  
ATOM    618  N   ASN A  81      -8.449  11.874  17.471  1.00  6.88           N  
ATOM    619  CA  ASN A  81      -8.869  11.528  18.835  1.00  6.57           C  
ATOM    620  C   ASN A  81      -7.694  11.331  19.769  1.00  5.68           C  
ATOM    621  O   ASN A  81      -7.166  10.224  19.948  1.00  7.45           O  
ATOM    622  CB  ASN A  81      -9.693  10.256  18.775  1.00  6.10           C  
ATOM    623  CG  ASN A  81     -10.389   9.935  20.076  1.00  6.43           C  
ATOM    624  OD1 ASN A  81      -9.984  10.439  21.112  1.00  8.57           O  
ATOM    625  ND2 ASN A  81     -11.462   9.176  20.001  1.00  7.87           N  
ATOM    626  N   ALA A  82      -7.187  12.461  20.260  1.00  6.37           N  
ATOM    627  CA  ALA A  82      -6.004  12.436  21.109  1.00  6.77           C  
ATOM    628  C   ALA A  82      -6.157  11.499  22.284  1.00  6.51           C  
ATOM    629  O   ALA A  82      -5.234  10.784  22.680  1.00  7.52           O  
ATOM    630  CB  ALA A  82      -5.726  13.826  21.655  1.00  9.97           C  
ATOM    631  N   GLY A  83      -7.331  11.503  22.879  1.00  6.27           N  
ATOM    632  CA  GLY A  83      -7.494  10.641  24.051  1.00  6.61           C  
ATOM    633  C   GLY A  83      -7.422   9.163  23.756  1.00  5.62           C  
ATOM    634  O   GLY A  83      -6.766   8.431  24.498  1.00  7.26           O  
ATOM    635  N   ALA A  84      -7.984   8.769  22.604  1.00  6.71           N  
ATOM    636  CA  ALA A  84      -7.925   7.377  22.198  1.00  6.68           C  
ATOM    637  C   ALA A  84      -6.491   6.982  21.862  1.00  6.77           C  
ATOM    638  O   ALA A  84      -5.997   5.918  22.209  1.00  8.05           O  
ATOM    639  CB  ALA A  84      -8.858   7.138  21.026  1.00  6.95           C  
ATOM    640  N   LEU A  85      -5.808   7.893  21.159  1.00  6.69           N  
ATOM    641  CA  LEU A  85      -4.405   7.674  20.786  1.00  6.58           C  
ATOM    642  C   LEU A  85      -3.521   7.560  22.042  1.00  7.01           C  
ATOM    643  O   LEU A  85      -2.722   6.633  22.136  1.00  6.54           O  
ATOM    644  CB  LEU A  85      -3.888   8.784  19.881  1.00  5.87           C  
ATOM    645  CG  LEU A  85      -4.439   8.952  18.469  1.00  6.06           C  
ATOM    646  CD1 LEU A  85      -3.867  10.187  17.807  1.00  7.91           C  
ATOM    647  CD2 LEU A  85      -4.138   7.731  17.611  1.00  6.84           C  
ATOM    648  N   GLU A  86      -3.764   8.426  23.030  1.00  6.76           N  
ATOM    649  CA  GLU A  86      -2.976   8.407  24.246  1.00  8.14           C  
ATOM    650  C   GLU A  86      -3.139   7.057  24.928  1.00  6.87           C  
ATOM    651  O   GLU A  86      -2.202   6.502  25.514  1.00  6.85           O  
ATOM    652  CB  GLU A  86      -3.412   9.511  25.211  1.00 13.75           C  
ATOM    653  CG  GLU A  86      -2.968  10.924  24.904  1.00 22.23           C  
ATOM    654  CD  GLU A  86      -3.592  11.967  25.821  1.00 29.24           C  
ATOM    655  OE1 GLU A  86      -3.900  11.609  26.996  1.00 38.01           O  
ATOM    656  OE2 GLU A  86      -4.059  12.990  25.251  1.00 41.47           O  
ATOM    657  N   GLY A  87      -4.370   6.581  24.999  1.00  6.99           N  
ATOM    658  CA  GLY A  87      -4.670   5.363  25.697  1.00  7.25           C  
ATOM    659  C   GLY A  87      -3.980   4.179  25.087  1.00  7.44           C  
ATOM    660  O   GLY A  87      -3.318   3.368  25.775  1.00  9.12           O  
ATOM    661  N   GLN A  88      -3.985   4.132  23.744  1.00  6.90           N  
ATOM    662  CA  GLN A  88      -3.261   3.041  23.076  1.00  7.16           C  
ATOM    663  C   GLN A  88      -1.746   3.138  23.247  1.00  6.37           C  
ATOM    664  O   GLN A  88      -0.993   2.175  23.425  1.00  6.46           O  
ATOM    665  CB  GLN A  88      -3.652   3.060  21.583  1.00  8.98           C  
ATOM    666  CG  GLN A  88      -5.063   2.548  21.351  1.00 10.48           C  
ATOM    667  CD  GLN A  88      -5.298   1.078  21.601  1.00 12.53           C  
ATOM    668  OE1 GLN A  88      -6.455   0.624  21.786  1.00 20.73           O  
ATOM    669  NE2 GLN A  88      -4.358   0.225  21.237  1.00  9.75           N  
ATOM    670  N   CYS A  89      -1.196   4.363  23.188  1.00  6.05           N  
ATOM    671  CA  CYS A  89       0.226   4.618  23.371  1.00  5.72           C  
ATOM    672  C   CYS A  89       0.662   4.196  24.766  1.00  5.43           C  
ATOM    673  O   CYS A  89       1.798   3.793  24.929  1.00  6.66           O  
ATOM    674  CB  CYS A  89       0.542   6.093  23.086  1.00  5.80           C  
ATOM    675  SG  CYS A  89       0.573   6.499  21.331  1.00  6.79           S  
ATOM    676  N   LYS A  90      -0.174   4.464  25.788  1.00  6.49           N  
ATOM    677  CA  LYS A  90       0.251   4.193  27.156  1.00  7.33           C  
ATOM    678  C   LYS A  90       0.516   2.704  27.322  1.00  6.72           C  
ATOM    679  O   LYS A  90       1.511   2.251  27.911  1.00  7.04           O  
ATOM    680  CB  LYS A  90      -0.820   4.699  28.112  1.00  8.35           C  
ATOM    681  CG  LYS A  90      -0.507   4.459  29.567  1.00 11.22           C  
ATOM    682  CD  LYS A  90      -1.615   4.998  30.448  1.00 15.52           C  
ATOM    683  CE  LYS A  90      -1.390   4.686  31.916  1.00 19.83           C  
ATOM    684  NZ  LYS A  90      -2.541   5.192  32.760  1.00 27.46           N  
ATOM    685  N   THR A  91      -0.397   1.887  26.788  1.00  6.22           N  
ATOM    686  CA  THR A  91      -0.246   0.437  26.892  1.00  6.94           C  
ATOM    687  C   THR A  91       0.973  -0.046  26.146  1.00  7.57           C  
ATOM    688  O   THR A  91       1.772  -0.828  26.657  1.00  7.07           O  
ATOM    689  CB  THR A  91      -1.495  -0.242  26.316  1.00  7.67           C  
ATOM    690  OG1 THR A  91      -2.651   0.216  27.046  1.00 11.26           O  
ATOM    691  CG2 THR A  91      -1.390  -1.769  26.434  1.00 10.79           C  
ATOM    692  N   PHE A  92       1.132   0.483  24.940  1.00  6.49           N  
ATOM    693  CA  PHE A  92       2.248   0.144  24.056  1.00  5.90           C  
ATOM    694  C   PHE A  92       3.596   0.477  24.679  1.00  5.58           C  
ATOM    695  O   PHE A  92       4.526  -0.331  24.740  1.00  6.05           O  
ATOM    696  CB  PHE A  92       2.005   0.909  22.761  1.00  6.87           C  
ATOM    697  CG  PHE A  92       3.188   0.993  21.814  1.00  6.38           C  
ATOM    698  CD1 PHE A  92       3.694  -0.143  21.206  1.00  5.60           C  
ATOM    699  CD2 PHE A  92       3.758   2.222  21.528  1.00  7.51           C  
ATOM    700  CE1 PHE A  92       4.776  -0.039  20.337  1.00  6.09           C  
ATOM    701  CE2 PHE A  92       4.825   2.336  20.669  1.00  7.74           C  
ATOM    702  CZ  PHE A  92       5.313   1.194  20.050  1.00  7.20           C  
ATOM    703  N   ALA A  93       3.660   1.702  25.207  1.00  6.87           N  
ATOM    704  CA  ALA A  93       4.881   2.141  25.899  1.00  6.92           C  
ATOM    705  C   ALA A  93       5.231   1.249  27.073  1.00  7.30           C  
ATOM    706  O   ALA A  93       6.390   0.897  27.275  1.00  6.81           O  
ATOM    707  CB  ALA A  93       4.715   3.569  26.392  1.00  7.35           C  
ATOM    708  N   ALA A  94       4.232   0.983  27.916  1.00  7.64           N  
ATOM    709  CA  ALA A  94       4.508   0.176  29.097  1.00  8.12           C  
ATOM    710  C   ALA A  94       5.037  -1.194  28.721  1.00  7.39           C  
ATOM    711  O   ALA A  94       6.007  -1.683  29.306  1.00  7.53           O  
ATOM    712  CB  ALA A  94       3.248   0.051  29.929  1.00 10.66           C  
ATOM    713  N   ASN A  95       4.440  -1.814  27.716  1.00  7.03           N  
ATOM    714  CA  ASN A  95       4.945  -3.128  27.294  1.00  7.48           C  
ATOM    715  C   ASN A  95       6.344  -3.136  26.741  1.00  6.74           C  
ATOM    716  O   ASN A  95       7.113  -4.065  26.983  1.00  7.51           O  
ATOM    717  CB  ASN A  95       3.936  -3.701  26.270  1.00  7.68           C  
ATOM    718  CG  ASN A  95       2.581  -4.108  26.788  1.00  9.05           C  
ATOM    719  OD1 ASN A  95       1.563  -4.260  26.047  1.00 11.55           O  
ATOM    720  ND2 ASN A  95       2.454  -4.496  28.031  1.00 10.92           N  
ATOM    721  N   HIS A  96       6.612  -2.117  25.933  1.00  6.10           N  
ATOM    722  CA  HIS A  96       7.939  -2.063  25.305  1.00  5.57           C  
ATOM    723  C   HIS A  96       9.001  -1.536  26.259  1.00  6.32           C  
ATOM    724  O   HIS A  96      10.072  -2.132  26.333  1.00  6.49           O  
ATOM    725  CB  HIS A  96       7.841  -1.243  24.014  1.00  5.55           C  
ATOM    726  CG  HIS A  96       7.137  -1.990  22.912  1.00  5.27           C  
ATOM    727  ND1 HIS A  96       5.769  -2.197  22.893  1.00  5.62           N  
ATOM    728  CD2 HIS A  96       7.618  -2.584  21.801  1.00  5.05           C  
ATOM    729  CE1 HIS A  96       5.459  -2.897  21.798  1.00  5.33           C  
ATOM    730  NE2 HIS A  96       6.577  -3.142  21.119  1.00  5.09           N  
ATOM    731  N   LYS A  97       8.664  -0.603  27.155  1.00  7.00           N  
ATOM    732  CA  LYS A  97       9.591  -0.203  28.222  1.00  6.72           C  
ATOM    733  C   LYS A  97      10.004  -1.383  29.077  1.00  7.16           C  
ATOM    734  O   LYS A  97      11.178  -1.496  29.445  1.00  7.73           O  
ATOM    735  CB  LYS A  97       8.934   0.866  29.104  1.00  8.96           C  
ATOM    736  CG  LYS A  97       9.863   1.443  30.158  1.00  8.70           C  
ATOM    737  CD  LYS A  97       9.056   2.342  31.102  1.00 11.36           C  
ATOM    738  CE  LYS A  97      10.032   2.926  32.111  1.00 16.73           C  
ATOM    739  NZ  LYS A  97       9.468   4.055  32.884  1.00 24.72           N  
ATOM    740  N   ALA A  98       9.071  -2.256  29.402  1.00  7.31           N  
ATOM    741  CA  ALA A  98       9.344  -3.426  30.230  1.00  8.69           C  
ATOM    742  C   ALA A  98      10.283  -4.419  29.555  1.00  9.13           C  
ATOM    743  O   ALA A  98      10.978  -5.152  30.270  1.00 10.93           O  
ATOM    744  CB  ALA A  98       8.038  -4.112  30.593  1.00  9.51           C  
ATOM    745  N   ARG A  99      10.439  -4.332  28.254  1.00  8.37           N  
ATOM    746  CA  ARG A  99      11.430  -5.124  27.534  1.00  8.60           C  
ATOM    747  C   ARG A  99      12.822  -4.502  27.498  1.00  9.06           C  
ATOM    748  O   ARG A  99      13.711  -5.074  26.838  1.00  9.00           O  
ATOM    749  CB  ARG A  99      10.964  -5.375  26.084  1.00  7.50           C  
ATOM    750  CG  ARG A  99       9.704  -6.175  26.017  1.00  7.66           C  
ATOM    751  CD  ARG A  99       9.101  -6.304  24.624  1.00  9.52           C  
ATOM    752  NE  ARG A  99       7.888  -7.130  24.780  1.00 10.16           N  
ATOM    753  CZ  ARG A  99       6.648  -6.850  24.445  1.00  9.87           C  
ATOM    754  NH1 ARG A  99       6.305  -5.716  23.832  1.00  9.16           N  
ATOM    755  NH2 ARG A  99       5.729  -7.752  24.726  1.00 12.52           N  
ATOM    756  N   GLY A 100      12.991  -3.307  28.027  1.00  8.06           N  
ATOM    757  CA  GLY A 100      14.251  -2.592  27.929  1.00  8.70           C  
ATOM    758  C   GLY A 100      14.435  -1.794  26.643  1.00  7.94           C  
ATOM    759  O   GLY A 100      15.549  -1.374  26.285  1.00  9.62           O  
ATOM    760  N   ILE A 101      13.340  -1.668  25.898  1.00  7.53           N  
ATOM    761  CA  ILE A 101      13.316  -0.957  24.637  1.00  6.11           C  
ATOM    762  C   ILE A 101      13.281   0.534  24.934  1.00  6.13           C  
ATOM    763  O   ILE A 101      12.603   0.979  25.855  1.00  8.68           O  
ATOM    764  CB  ILE A 101      12.149  -1.407  23.749  1.00  5.50           C  
ATOM    765  CG1 ILE A 101      12.296  -2.892  23.377  1.00  7.11           C  
ATOM    766  CG2 ILE A 101      12.017  -0.581  22.498  1.00  7.69           C  
ATOM    767  CD1 ILE A 101      11.061  -3.542  22.810  1.00  8.07           C  
ATOM    768  N   SER A 102      14.059   1.291  24.176  1.00  6.81           N  
ATOM    769  CA  SER A 102      14.117   2.736  24.328  1.00  6.95           C  
ATOM    770  C   SER A 102      13.132   3.479  23.426  1.00  6.35           C  
ATOM    771  O   SER A 102      12.688   3.033  22.361  1.00  6.58           O  
ATOM    772  CB  SER A 102      15.520   3.257  24.046  1.00  7.03           C  
ATOM    773  OG  SER A 102      15.845   3.150  22.650  1.00  8.39           O  
ATOM    774  N   ALA A 103      12.892   4.736  23.817  1.00  6.60           N  
ATOM    775  CA  ALA A 103      12.097   5.601  22.955  1.00  6.91           C  
ATOM    776  C   ALA A 103      12.750   5.777  21.577  1.00  6.58           C  
ATOM    777  O   ALA A 103      12.131   5.831  20.527  1.00  7.25           O  
ATOM    778  CB  ALA A 103      11.875   6.921  23.683  1.00  9.81           C  
ATOM    779  N   GLY A 104      14.085   5.806  21.554  1.00  6.66           N  
ATOM    780  CA  GLY A 104      14.784   5.967  20.287  1.00  7.28           C  
ATOM    781  C   GLY A 104      14.642   4.767  19.395  1.00  6.85           C  
ATOM    782  O   GLY A 104      14.517   4.954  18.190  1.00  7.24           O  
ATOM    783  N   GLN A 105      14.540   3.549  19.922  1.00  6.45           N  
ATOM    784  CA  GLN A 105      14.271   2.381  19.080  1.00  5.57           C  
ATOM    785  C   GLN A 105      12.862   2.411  18.492  1.00  5.87           C  
ATOM    786  O   GLN A 105      12.648   2.037  17.353  1.00  6.35           O  
ATOM    787  CB  GLN A 105      14.504   1.083  19.864  1.00  5.17           C  
ATOM    788  CG  GLN A 105      15.989   0.849  20.167  1.00  7.05           C  
ATOM    789  CD  GLN A 105      16.200  -0.287  21.145  1.00  7.46           C  
ATOM    790  OE1 GLN A 105      15.539  -0.397  22.158  1.00  7.20           O  
ATOM    791  NE2 GLN A 105      17.157  -1.134  20.790  1.00  7.68           N  
ATOM    792  N   LEU A 106      11.890   2.905  19.257  1.00  6.56           N  
ATOM    793  CA  LEU A 106      10.527   3.026  18.737  1.00  6.63           C  
ATOM    794  C   LEU A 106      10.553   4.078  17.630  1.00  6.99           C  
ATOM    795  O   LEU A 106       9.937   3.900  16.599  1.00  7.01           O  
ATOM    796  CB  LEU A 106       9.606   3.436  19.849  1.00  6.87           C  
ATOM    797  CG  LEU A 106       9.452   2.505  21.060  1.00  7.00           C  
ATOM    798  CD1 LEU A 106       8.437   3.030  22.067  1.00  9.25           C  
ATOM    799  CD2 LEU A 106       9.114   1.107  20.587  1.00  7.92           C  
ATOM    800  N   GLU A 107      11.267   5.187  17.850  1.00  7.00           N  
ATOM    801  CA  GLU A 107      11.386   6.211  16.843  1.00  8.48           C  
ATOM    802  C   GLU A 107      12.024   5.645  15.582  1.00  8.18           C  
ATOM    803  O   GLU A 107      11.633   6.007  14.446  1.00  8.78           O  
ATOM    804  CB  GLU A 107      12.176   7.398  17.442  1.00 11.36           C  
ATOM    805  CG  GLU A 107      11.941   8.672  16.643  1.00 19.74           C  
ATOM    806  CD  GLU A 107      12.563   9.859  17.367  1.00 24.23           C  
ATOM    807  OE1 GLU A 107      12.740   9.655  18.610  1.00 32.92           O  
ATOM    808  OE2 GLU A 107      13.465  10.447  16.714  1.00 30.28           O  
ATOM    809  N   ALA A 108      13.000   4.745  15.682  1.00  7.29           N  
ATOM    810  CA  ALA A 108      13.646   4.170  14.512  1.00  6.70           C  
ATOM    811  C   ALA A 108      12.648   3.366  13.696  1.00  6.17           C  
ATOM    812  O   ALA A 108      12.678   3.341  12.470  1.00  7.03           O  
ATOM    813  CB  ALA A 108      14.814   3.302  14.930  1.00  9.80           C  
ATOM    814  N   ALA A 109      11.828   2.608  14.426  1.00  5.70           N  
ATOM    815  CA  ALA A 109      10.796   1.833  13.744  1.00  5.70           C  
ATOM    816  C   ALA A 109       9.840   2.734  12.969  1.00  6.00           C  
ATOM    817  O   ALA A 109       9.514   2.427  11.817  1.00  5.42           O  
ATOM    818  CB  ALA A 109      10.050   0.500  14.715  1.00  6.99           C  
ATOM    819  N   PHE A 110       9.391   3.838  13.570  1.00  5.58           N  
ATOM    820  CA  PHE A 110       8.534   4.786  12.861  1.00  6.38           C  
ATOM    821  C   PHE A 110       9.234   5.395  11.638  1.00  5.90           C  
ATOM    822  O   PHE A 110       8.641   5.635  10.615  1.00  6.27           O  
ATOM    823  CB  PHE A 110       8.086   5.923  13.791  1.00  5.82           C  
ATOM    824  CG  PHE A 110       6.961   5.605  14.748  1.00  6.18           C  
ATOM    825  CD1 PHE A 110       5.731   5.250  14.259  1.00  7.09           C  
ATOM    826  CD2 PHE A 110       7.098   5.672  16.110  1.00  6.37           C  
ATOM    827  CE1 PHE A 110       4.661   4.951  15.062  1.00  8.14           C  
ATOM    828  CE2 PHE A 110       6.046   5.378  16.955  1.00  6.77           C  
ATOM    829  CZ  PHE A 110       4.819   5.039  16.421  1.00  7.41           C  
ATOM    830  N   LYS A 111      10.545   5.627  11.720  1.00  6.03           N  
ATOM    831  CA  LYS A 111      11.264   6.227  10.599  1.00  7.19           C  
ATOM    832  C   LYS A 111      11.379   5.230   9.450  1.00  5.84           C  
ATOM    833  O   LYS A 111      11.170   5.575   8.285  1.00  5.90           O  
ATOM    834  CB  LYS A 111      12.665   6.700  10.981  1.00 11.11           C  
ATOM    835  CG  LYS A 111      13.507   7.180   9.805  1.00 18.13           C  
ATOM    836  CD  LYS A 111      14.795   7.858  10.247  1.00 23.48           C  
ATOM    837  CE  LYS A 111      15.526   8.541   9.111  1.00 27.62           C  
ATOM    838  NZ  LYS A 111      16.062   9.889   9.495  1.00 37.19           N  
ATOM    839  N   VAL A 112      11.657   3.975   9.785  1.00  5.72           N  
ATOM    840  CA  VAL A 112      11.703   2.941   8.759  1.00  5.68           C  
ATOM    841  C   VAL A 112      10.317   2.780   8.141  1.00  4.89           C  
ATOM    842  O   VAL A 112      10.192   2.715   6.922  1.00  6.45           O  
ATOM    843  CB  VAL A 112      12.216   1.597   9.317  1.00  6.74           C  
ATOM    844  CG1 VAL A 112      12.072   0.520   8.233  1.00  7.31           C  
ATOM    845  CG2 VAL A 112      13.657   1.738   9.789  1.00  8.63           C  
ATOM    846  N   LEU A 113       9.259   2.782   8.951  1.00  4.82           N  
ATOM    847  CA  LEU A 113       7.907   2.663   8.417  1.00  4.84           C  
ATOM    848  C   LEU A 113       7.559   3.808   7.482  1.00  5.13           C  
ATOM    849  O   LEU A 113       6.944   3.582   6.438  1.00  5.89           O  
ATOM    850  CB  LEU A 113       6.926   2.602   9.595  1.00  5.81           C  
ATOM    851  CG  LEU A 113       5.454   2.412   9.238  1.00  5.96           C  
ATOM    852  CD1 LEU A 113       5.241   1.065   8.557  1.00  7.64           C  
ATOM    853  CD2 LEU A 113       4.581   2.543  10.479  1.00  8.28           C  
ATOM    854  N   ALA A 114       7.903   5.041   7.878  1.00  4.93           N  
ATOM    855  CA  ALA A 114       7.550   6.204   7.061  1.00  4.81           C  
ATOM    856  C   ALA A 114       8.148   6.069   5.663  1.00  5.86           C  
ATOM    857  O   ALA A 114       7.481   6.329   4.674  1.00  6.45           O  
ATOM    858  CB  ALA A 114       7.994   7.492   7.707  1.00  7.93           C  
ATOM    859  N   GLY A 115       9.391   5.609   5.563  1.00  5.19           N  
ATOM    860  CA  GLY A 115       9.932   5.413   4.241  1.00  5.70           C  
ATOM    861  C   GLY A 115       9.373   4.213   3.513  1.00  5.45           C  
ATOM    862  O   GLY A 115       9.151   4.269   2.304  1.00  6.54           O  
ATOM    863  N   PHE A 116       9.095   3.129   4.237  1.00  5.64           N  
ATOM    864  CA  PHE A 116       8.534   1.923   3.645  1.00  5.31           C  
ATOM    865  C   PHE A 116       7.187   2.207   3.025  1.00  5.15           C  
ATOM    866  O   PHE A 116       6.885   1.652   1.983  1.00  5.68           O  
ATOM    867  CB  PHE A 116       8.424   0.872   4.750  1.00  5.73           C  
ATOM    868  CG  PHE A 116       7.967  -0.490   4.274  1.00  5.97           C  
ATOM    869  CD1 PHE A 116       8.899  -1.408   3.850  1.00  7.54           C  
ATOM    870  CD2 PHE A 116       6.625  -0.826   4.259  1.00  6.97           C  
ATOM    871  CE1 PHE A 116       8.501  -2.669   3.433  1.00  7.44           C  
ATOM    872  CE2 PHE A 116       6.219  -2.078   3.851  1.00  7.64           C  
ATOM    873  CZ  PHE A 116       7.151  -2.998   3.432  1.00  8.08           C  
ATOM    874  N   MET A 117       6.440   3.111   3.651  1.00  3.99           N  
ATOM    875  CA  MET A 117       5.084   3.411   3.219  1.00  5.01           C  
ATOM    876  C   MET A 117       5.017   4.182   1.911  1.00  4.98           C  
ATOM    877  O   MET A 117       3.936   4.260   1.313  1.00  5.12           O  
ATOM    878  CB  MET A 117       4.330   4.154   4.330  1.00  4.50           C  
ATOM    879  CG  MET A 117       3.922   3.275   5.491  1.00  5.40           C  
ATOM    880  SD  MET A 117       2.898   1.850   5.011  1.00  5.75           S  
ATOM    881  CE  MET A 117       1.556   2.687   4.186  1.00  5.23           C  
ATOM    882  N   LYS A 118       6.162   4.689   1.431  1.00  4.97           N  
ATOM    883  CA  LYS A 118       6.211   5.361   0.130  1.00  6.43           C  
ATOM    884  C   LYS A 118       5.756   4.400  -0.948  1.00  5.80           C  
ATOM    885  O   LYS A 118       5.167   4.871  -1.918  1.00  8.52           O  
ATOM    886  CB  LYS A 118       7.593   5.924  -0.196  1.00  6.92           C  
ATOM    887  CG  LYS A 118       7.970   7.082   0.723  1.00  8.13           C  
ATOM    888  CD  LYS A 118       9.395   7.546   0.469  1.00 11.62           C  
ATOM    889  CE  LYS A 118       9.595   8.257  -0.838  1.00 15.26           C  
ATOM    890  NZ  LYS A 118      10.996   8.785  -0.932  1.00 25.25           N  
ATOM    891  N   SER A 119       5.891   3.088  -0.792  1.00  6.16           N  
ATOM    892  CA  SER A 119       5.535   2.135  -1.824  1.00  6.70           C  
ATOM    893  C   SER A 119       4.018   1.930  -1.890  1.00  5.94           C  
ATOM    894  O   SER A 119       3.577   1.316  -2.882  1.00  7.55           O  
ATOM    895  CB  SER A 119       6.274   0.817  -1.601  1.00  7.94           C  
ATOM    896  OG  SER A 119       7.683   0.928  -1.576  1.00 10.60           O  
ATOM    897  N   TYR A 120       3.272   2.439  -0.928  1.00  5.43           N  
ATOM    898  CA  TYR A 120       1.837   2.256  -0.807  1.00  5.46           C  
ATOM    899  C   TYR A 120       1.149   3.596  -0.963  1.00  6.30           C  
ATOM    900  O   TYR A 120       0.059   3.790  -0.429  1.00  7.48           O  
ATOM    901  CB  TYR A 120       1.448   1.532   0.538  1.00  6.59           C  
ATOM    902  CG  TYR A 120       2.169   0.209   0.501  1.00  6.49           C  
ATOM    903  CD1 TYR A 120       1.565  -0.883  -0.119  1.00  7.77           C  
ATOM    904  CD2 TYR A 120       3.440   0.028   1.039  1.00  7.83           C  
ATOM    905  CE1 TYR A 120       2.180  -2.124  -0.188  1.00  9.13           C  
ATOM    906  CE2 TYR A 120       4.083  -1.208   0.947  1.00  9.85           C  
ATOM    907  CZ  TYR A 120       3.440  -2.262   0.345  1.00 10.16           C  
ATOM    908  OH  TYR A 120       4.106  -3.454   0.250  1.00 13.32           O  
ATOM    909  N   GLY A 121       1.738   4.543  -1.675  1.00  5.83           N  
ATOM    910  CA  GLY A 121       1.233   5.878  -1.843  1.00  6.68           C  
ATOM    911  C   GLY A 121       1.453   6.820  -0.690  1.00  5.93           C  
ATOM    912  O   GLY A 121       0.844   7.886  -0.636  1.00  6.73           O  
ATOM    913  N   GLY A 122       2.160   6.382   0.351  1.00  5.50           N  
ATOM    914  CA  GLY A 122       2.394   7.223   1.493  1.00  4.85           C  
ATOM    915  C   GLY A 122       3.305   8.393   1.199  1.00  5.21           C  
ATOM    916  O   GLY A 122       4.311   8.281   0.494  1.00  6.63           O  
ATOM    917  N   ASP A 123       2.916   9.530   1.761  1.00  4.68           N  
ATOM    918  CA  ASP A 123       3.727  10.717   1.845  1.00  5.78           C  
ATOM    919  C   ASP A 123       4.619  10.568   3.081  1.00  5.19           C  
ATOM    920  O   ASP A 123       4.087  10.459   4.177  1.00  5.97           O  
ATOM    921  CB  ASP A 123       2.846  11.938   2.008  1.00  6.90           C  
ATOM    922  CG  ASP A 123       3.581  13.210   2.377  1.00  7.88           C  
ATOM    923  OD1 ASP A 123       4.812  13.256   2.300  1.00  7.80           O  
ATOM    924  OD2 ASP A 123       2.909  14.236   2.630  1.00  8.97           O  
ATOM    925  N   GLU A 124       5.914  10.371   2.890  1.00  5.25           N  
ATOM    926  CA  GLU A 124       6.813  10.154   4.018  1.00  6.03           C  
ATOM    927  C   GLU A 124       6.696  11.279   5.043  1.00  5.58           C  
ATOM    928  O   GLU A 124       6.780  11.019   6.246  1.00  7.63           O  
ATOM    929  CB  GLU A 124       8.269  10.009   3.566  1.00  7.36           C  
ATOM    930  CG  GLU A 124       9.264   9.621   4.640  1.00  8.00           C  
ATOM    931  CD  GLU A 124      10.650   9.383   4.089  1.00  8.97           C  
ATOM    932  OE1 GLU A 124      10.941   9.719   2.930  1.00 14.30           O  
ATOM    933  OE2 GLU A 124      11.423   8.741   4.819  1.00 12.28           O  
ATOM    934  N   GLY A 125       6.414  12.495   4.598  1.00  5.36           N  
ATOM    935  CA  GLY A 125       6.212  13.607   5.503  1.00  5.63           C  
ATOM    936  C   GLY A 125       4.963  13.450   6.347  1.00  5.29           C  
ATOM    937  O   GLY A 125       4.914  13.895   7.504  1.00  6.00           O  
ATOM    938  N   ALA A 126       3.923  12.843   5.800  1.00  5.76           N  
ATOM    939  CA  ALA A 126       2.696  12.592   6.565  1.00  5.39           C  
ATOM    940  C   ALA A 126       2.898  11.530   7.629  1.00  4.88           C  
ATOM    941  O   ALA A 126       2.445  11.703   8.766  1.00  5.58           O  
ATOM    942  CB  ALA A 126       1.568  12.215   5.618  1.00  5.66           C  
ATOM    943  N   TRP A 127       3.565  10.441   7.225  1.00  5.24           N  
ATOM    944  CA  TRP A 127       3.911   9.408   8.208  1.00  4.19           C  
ATOM    945  C   TRP A 127       4.853   9.957   9.262  1.00  4.00           C  
ATOM    946  O   TRP A 127       4.666   9.674  10.458  1.00  5.45           O  
ATOM    947  CB  TRP A 127       4.507   8.194   7.465  1.00  4.71           C  
ATOM    948  CG  TRP A 127       3.379   7.366   6.896  1.00  3.86           C  
ATOM    949  CD1 TRP A 127       2.852   7.444   5.645  1.00  4.48           C  
ATOM    950  CD2 TRP A 127       2.651   6.352   7.600  1.00  4.04           C  
ATOM    951  NE1 TRP A 127       1.837   6.530   5.522  1.00  5.12           N  
ATOM    952  CE2 TRP A 127       1.684   5.841   6.694  1.00  4.34           C  
ATOM    953  CE3 TRP A 127       2.697   5.800   8.874  1.00  4.84           C  
ATOM    954  CZ2 TRP A 127       0.811   4.834   7.070  1.00  4.62           C  
ATOM    955  CZ3 TRP A 127       1.814   4.785   9.240  1.00  5.51           C  
ATOM    956  CH2 TRP A 127       0.859   4.291   8.338  1.00  5.16           C  
ATOM    957  N   THR A 128       5.735  10.875   8.909  1.00  4.68           N  
ATOM    958  CA  THR A 128       6.603  11.527   9.891  1.00  5.72           C  
ATOM    959  C   THR A 128       5.802  12.360  10.879  1.00  4.86           C  
ATOM    960  O   THR A 128       6.098  12.356  12.093  1.00  6.83           O  
ATOM    961  CB  THR A 128       7.663  12.404   9.154  1.00  6.14           C  
ATOM    962  OG1 THR A 128       8.486  11.550   8.360  1.00  8.66           O  
ATOM    963  CG2 THR A 128       8.515  13.135  10.165  1.00 10.01           C  
ATOM    964  N   ALA A 129       4.808  13.088  10.367  1.00  5.99           N  
ATOM    965  CA  ALA A 129       3.968  13.921  11.245  1.00  5.38           C  
ATOM    966  C   ALA A 129       3.173  13.054  12.206  1.00  5.81           C  
ATOM    967  O   ALA A 129       3.040  13.361  13.393  1.00  6.31           O  
ATOM    968  CB  ALA A 129       3.112  14.869  10.390  1.00  5.39           C  
ATOM    969  N   VAL A 130       2.589  11.956  11.715  1.00  4.86           N  
ATOM    970  CA  VAL A 130       1.825  11.080  12.594  1.00  5.56           C  
ATOM    971  C   VAL A 130       2.733  10.461  13.650  1.00  6.02           C  
ATOM    972  O   VAL A 130       2.397  10.421  14.845  1.00  6.52           O  
ATOM    973  CB  VAL A 130       1.089   9.999  11.782  1.00  5.75           C  
ATOM    974  CG1 VAL A 130       0.580   8.889  12.688  1.00  7.84           C  
ATOM    975  CG2 VAL A 130      -0.099  10.581  11.018  1.00  7.62           C  
ATOM    976  N   ALA A 131       3.913  10.003  13.251  1.00  5.44           N  
ATOM    977  CA  ALA A 131       4.876   9.428  14.174  1.00  5.67           C  
ATOM    978  C   ALA A 131       5.318  10.438  15.228  1.00  5.85           C  
ATOM    979  O   ALA A 131       5.462  10.100  16.398  1.00  6.35           O  
ATOM    980  CB  ALA A 131       6.088   8.870  13.448  1.00  7.01           C  
ATOM    981  N   GLY A 132       5.480  11.700  14.828  1.00  7.01           N  
ATOM    982  CA  GLY A 132       5.880  12.733  15.779  1.00  7.13           C  
ATOM    983  C   GLY A 132       4.784  12.900  16.811  1.00  7.27           C  
ATOM    984  O   GLY A 132       5.061  13.111  17.990  1.00  8.00           O  
ATOM    985  N   ALA A 133       3.518  12.913  16.367  1.00  7.13           N  
ATOM    986  CA  ALA A 133       2.412  13.044  17.318  1.00  6.87           C  
ATOM    987  C   ALA A 133       2.394  11.886  18.299  1.00  6.18           C  
ATOM    988  O   ALA A 133       2.291  12.067  19.526  1.00  8.84           O  
ATOM    989  CB  ALA A 133       1.105  13.138  16.555  1.00  8.84           C  
ATOM    990  N   LEU A 134       2.547  10.673  17.755  1.00  5.70           N  
ATOM    991  CA  LEU A 134       2.531   9.508  18.645  1.00  5.04           C  
ATOM    992  C   LEU A 134       3.738   9.505  19.582  1.00  5.49           C  
ATOM    993  O   LEU A 134       3.604   9.262  20.781  1.00  6.18           O  
ATOM    994  CB  LEU A 134       2.466   8.209  17.829  1.00  5.86           C  
ATOM    995  CG  LEU A 134       1.226   7.995  16.976  1.00  5.97           C  
ATOM    996  CD1 LEU A 134       1.465   6.862  15.979  1.00  7.08           C  
ATOM    997  CD2 LEU A 134       0.022   7.742  17.875  1.00  9.98           C  
ATOM    998  N   MET A 135       4.925   9.850  19.080  1.00  5.83           N  
ATOM    999  CA  MET A 135       6.102   9.874  19.952  1.00  6.16           C  
ATOM   1000  C   MET A 135       5.958  10.908  21.060  1.00  5.92           C  
ATOM   1001  O   MET A 135       6.449  10.683  22.164  1.00  8.43           O  
ATOM   1002  CB  MET A 135       7.361  10.080  19.136  1.00  7.33           C  
ATOM   1003  CG  MET A 135       7.816   8.857  18.341  1.00  8.90           C  
ATOM   1004  SD  MET A 135       8.119   7.381  19.322  1.00  9.40           S  
ATOM   1005  CE  MET A 135       9.258   8.020  20.553  1.00 15.00           C  
ATOM   1006  N   GLY A 136       5.264  12.011  20.833  1.00  7.59           N  
ATOM   1007  CA  GLY A 136       5.021  12.982  21.895  1.00  8.31           C  
ATOM   1008  C   GLY A 136       4.182  12.409  23.018  1.00  8.16           C  
ATOM   1009  O   GLY A 136       4.308  12.828  24.169  1.00 10.19           O  
ATOM   1010  N   MET A 137       3.338  11.427  22.721  1.00  7.05           N  
ATOM   1011  CA  MET A 137       2.555  10.730  23.736  1.00  7.75           C  
ATOM   1012  C   MET A 137       3.374   9.633  24.411  1.00  7.75           C  
ATOM   1013  O   MET A 137       3.178   9.346  25.571  1.00  9.94           O  
ATOM   1014  CB  MET A 137       1.270  10.140  23.132  1.00  9.30           C  
ATOM   1015  CG  MET A 137       0.386  11.173  22.432  1.00  9.41           C  
ATOM   1016  SD  MET A 137      -0.964  10.409  21.498  1.00 10.62           S  
ATOM   1017  CE  MET A 137      -1.766  11.863  20.836  1.00 11.15           C  
ATOM   1018  N   ILE A 138       4.202   8.940  23.616  1.00  7.86           N  
ATOM   1019  CA  ILE A 138       4.956   7.781  24.040  1.00  8.23           C  
ATOM   1020  C   ILE A 138       6.140   8.148  24.916  1.00  9.50           C  
ATOM   1021  O   ILE A 138       6.311   7.508  25.955  1.00 10.05           O  
ATOM   1022  CB  ILE A 138       5.423   6.971  22.800  1.00  8.54           C  
ATOM   1023  CG1 ILE A 138       4.240   6.321  22.082  1.00  7.89           C  
ATOM   1024  CG2 ILE A 138       6.518   5.962  23.142  1.00  9.04           C  
ATOM   1025  CD1 ILE A 138       4.454   5.937  20.640  1.00  8.23           C  
ATOM   1026  N   ARG A 139       6.935   9.090  24.474  1.00 11.88           N  
ATOM   1027  CA  ARG A 139       8.191   9.433  25.153  1.00 14.34           C  
ATOM   1028  C   ARG A 139       8.046   9.633  26.656  1.00 15.45           C  
ATOM   1029  O   ARG A 139       8.875   9.109  27.432  1.00 16.16           O  
ATOM   1030  CB  ARG A 139       8.758  10.689  24.469  1.00 17.84           C  
ATOM   1031  CG  ARG A 139      10.211  10.683  24.120  1.00 20.98           C  
ATOM   1032  CD  ARG A 139      10.574  11.847  23.219  1.00 24.93           C  
ATOM   1033  NE  ARG A 139      10.916  11.444  21.849  1.00 27.47           N  
ATOM   1034  CZ  ARG A 139      10.322  11.982  20.776  1.00 30.86           C  
ATOM   1035  NH1 ARG A 139       9.377  12.917  20.929  1.00 32.30           N  
ATOM   1036  NH2 ARG A 139      10.646  11.602  19.542  1.00 35.16           N  
ATOM   1037  N   PRO A 140       7.037  10.368  27.147  1.00 15.43           N  
ATOM   1038  CA  PRO A 140       6.930  10.618  28.603  1.00 17.79           C  
ATOM   1039  C   PRO A 140       6.824   9.320  29.395  1.00 19.13           C  
ATOM   1040  O   PRO A 140       7.077   9.305  30.612  1.00 20.28           O  
ATOM   1041  CB  PRO A 140       5.643  11.432  28.746  1.00 18.69           C  
ATOM   1042  CG  PRO A 140       5.506  12.133  27.449  1.00 18.27           C  
ATOM   1043  CD  PRO A 140       6.078  11.209  26.400  1.00 16.53           C  
ATOM   1044  N   ASP A 141       6.369   8.278  28.731  1.00 18.13           N  
ATOM   1045  CA  ASP A 141       6.122   6.979  29.334  1.00 17.28           C  
ATOM   1046  C   ASP A 141       7.230   5.973  29.080  1.00 17.32           C  
ATOM   1047  O   ASP A 141       7.152   4.824  29.542  1.00 21.26           O  
ATOM   1048  CB  ASP A 141       4.757   6.470  28.836  1.00 17.49           C  
ATOM   1049  CG  ASP A 141       3.578   7.215  29.438  1.00 20.98           C  
ATOM   1050  OD1 ASP A 141       3.510   7.294  30.762  1.00 28.16           O  
ATOM   1051  OD2 ASP A 141       2.612   7.516  28.746  1.00 28.04           O  
ATOM   1052  N   MET A 142       8.357   6.412  28.524  1.00 17.41           N  
ATOM   1053  CA  MET A 142       9.446   5.488  28.228  1.00 17.56           C  
ATOM   1054  C   MET A 142      10.598   5.637  29.213  1.00 22.13           C  
ATOM   1055  O   MET A 142      10.486   6.346  30.216  1.00 22.98           O  
ATOM   1056  CB  MET A 142       9.941   5.702  26.791  1.00 16.59           C  
ATOM   1057  CG  MET A 142       8.999   5.204  25.704  1.00 14.05           C  
ATOM   1058  SD  MET A 142       8.463   3.502  25.911  1.00 12.71           S  
ATOM   1059  CE  MET A 142       9.937   2.609  25.391  1.00 12.94           C  
ATOM   1060  OXT MET A 142      11.481   4.747  29.131  1.00 31.16           O  
TER    1061      MET A 142                                                      
HETATM 1062  C   CYN A 145       6.708  -5.042  17.519  1.00  4.83           C  
HETATM 1063  N   CYN A 145       6.693  -5.522  16.471  1.00  7.18           N  
HETATM 1064 FE   HEM A 144       6.667  -4.192  19.272  1.00  5.39          FE  
HETATM 1065  CHA HEM A 144       5.170  -6.976  20.710  1.00  5.47           C  
HETATM 1066  CHB HEM A 144       3.577  -3.125  18.178  1.00  5.39           C  
HETATM 1067  CHC HEM A 144       8.057  -1.359  17.965  1.00  5.30           C  
HETATM 1068  CHD HEM A 144       9.832  -5.305  20.116  1.00  4.61           C  
HETATM 1069  NA  HEM A 144       4.811  -4.776  19.428  1.00  5.26           N  
HETATM 1070  C1A HEM A 144       4.431  -5.959  20.121  1.00  5.75           C  
HETATM 1071  C2A HEM A 144       2.960  -6.001  20.192  1.00  5.22           C  
HETATM 1072  C3A HEM A 144       2.450  -4.949  19.527  1.00  5.61           C  
HETATM 1073  C4A HEM A 144       3.669  -4.230  18.950  1.00  5.43           C  
HETATM 1074  CMA HEM A 144       0.998  -4.617  19.236  1.00  6.13           C  
HETATM 1075  CAA HEM A 144       2.079  -7.136  20.899  1.00  5.94           C  
HETATM 1076  CBA HEM A 144       1.622  -6.627  22.358  1.00  6.70           C  
HETATM 1077  CGA HEM A 144       2.814  -6.720  23.275  1.00  6.82           C  
HETATM 1078  O1A HEM A 144       3.270  -7.659  23.753  1.00 10.55           O  
HETATM 1079  O2A HEM A 144       3.366  -5.542  23.468  1.00  7.60           O  
HETATM 1080  NB  HEM A 144       5.972  -2.548  18.263  1.00  4.53           N  
HETATM 1081  C1B HEM A 144       4.691  -2.362  17.763  1.00  4.38           C  
HETATM 1082  C2B HEM A 144       4.556  -1.209  17.024  1.00  4.47           C  
HETATM 1083  C3B HEM A 144       5.766  -0.652  17.080  1.00  5.15           C  
HETATM 1084  C4B HEM A 144       6.649  -1.512  17.839  1.00  4.95           C  
HETATM 1085  CMB HEM A 144       3.350  -0.672  16.334  1.00  4.75           C  
HETATM 1086  CAB HEM A 144       6.172   0.523  16.450  1.00  8.00           C  
HETATM 1087  CBB HEM A 144       6.392   1.432  16.359  1.00 14.94           C  
HETATM 1088  NC  HEM A 144       8.534  -3.490  19.099  1.00  5.23           N  
HETATM 1089  C1C HEM A 144       9.001  -2.283  18.511  1.00  5.01           C  
HETATM 1090  C2C HEM A 144      10.432  -2.087  18.548  1.00  4.41           C  
HETATM 1091  C3C HEM A 144      10.880  -3.281  19.142  1.00  4.39           C  
HETATM 1092  C4C HEM A 144       9.751  -4.158  19.463  1.00  5.18           C  
HETATM 1093  CMC HEM A 144      11.167  -0.951  18.040  1.00  6.99           C  
HETATM 1094  CAC HEM A 144      12.236  -3.675  19.469  1.00  5.45           C  
HETATM 1095  CBC HEM A 144      13.333  -2.877  19.685  1.00  5.47           C  
HETATM 1096  ND  HEM A 144       7.364  -5.809  20.180  1.00  4.60           N  
HETATM 1097  C1D HEM A 144       8.771  -6.086  20.446  1.00  4.55           C  
HETATM 1098  C2D HEM A 144       8.766  -7.473  21.067  1.00  5.55           C  
HETATM 1099  C3D HEM A 144       7.403  -8.023  21.131  1.00  5.27           C  
HETATM 1100  C4D HEM A 144       6.572  -6.902  20.711  1.00  4.70           C  
HETATM 1101  CMD HEM A 144      10.060  -8.109  21.411  1.00  7.23           C  
HETATM 1102  CAD HEM A 144       7.020  -9.269  21.772  1.00  6.94           C  
HETATM 1103  CBD HEM A 144       7.437 -10.330  20.779  1.00  8.53           C  
HETATM 1104  CGD HEM A 144       7.111 -11.473  21.433  1.00 10.98           C  
HETATM 1105  O1D HEM A 144       5.971 -12.068  21.426  1.00 14.41           O  
HETATM 1106  O2D HEM A 144       7.833 -12.313  21.939  1.00 13.97           O  
HETATM 1107  O   HOH A 501      21.747 -12.264  13.378  1.00 11.09           O  
HETATM 1108  O   HOH A 502      -1.841  -9.508   2.710  1.00  9.56           O  
HETATM 1109  O   HOH A 503       2.299  -3.075  23.193  1.00 10.25           O  
HETATM 1110  O   HOH A 504      -5.064  19.501   5.164  1.00  8.63           O  
HETATM 1111  O   HOH A 505      -8.785  14.947  20.052  1.00  7.50           O  
HETATM 1112  O   HOH A 506       5.193  -7.536  -0.416  1.00  8.77           O  
HETATM 1113  O   HOH A 507      -1.924  -0.438  22.692  1.00  9.47           O  
HETATM 1114  O   HOH A 508      17.980   2.234  17.528  0.50 11.97           O  
HETATM 1115  O   HOH A 509       7.548  13.984  18.879  1.00 19.97           O  
HETATM 1116  O   HOH A 510      -0.257 -12.142  16.287  1.00 16.93           O  
HETATM 1117  O   HOH A 511       6.363  16.043   8.439  1.00 12.40           O  
HETATM 1118  O   HOH A 512      -2.074  -5.637  17.588  1.00  6.61           O  
HETATM 1119  O   HOH A 513       3.769  15.902   4.578  1.00  9.49           O  
HETATM 1120  O   HOH A 514       1.860  14.535  20.656  1.00 16.48           O  
HETATM 1121  O   HOH A 515      12.822  -5.872   3.205  1.00 15.39           O  
HETATM 1122  O   HOH A 516     -11.109  16.149  17.289  1.00 13.13           O  
HETATM 1123  O   HOH A 517      15.611   7.063  16.431  0.50 19.55           O  
HETATM 1124  O   HOH A 518      20.225 -19.103  12.174  1.00 13.42           O  
HETATM 1125  O   HOH A 519       7.225  10.856   0.302  1.00 13.30           O  
HETATM 1126  O   HOH A 520      17.443  -1.098  24.277  1.00 13.76           O  
HETATM 1127  O   HOH A 521       6.797 -15.083   7.750  1.00 11.55           O  
HETATM 1128  O   HOH A 522       1.185  16.007   1.706  1.00 14.61           O  
HETATM 1129  O   HOH A 523       3.592  -5.518  -1.354  1.00 11.54           O  
HETATM 1130  O   HOH A 524      -6.738  -3.178  15.194  1.00 25.24           O  
HETATM 1131  O   HOH A 525      12.382  -8.084  24.095  1.00 11.23           O  
HETATM 1132  O   HOH A 526       3.108  15.972  14.349  1.00 11.20           O  
HETATM 1133  O   HOH A 527      22.055 -13.391   9.203  1.00 23.19           O  
HETATM 1134  O   HOH A 528      -6.574   3.370   0.097  1.00 16.68           O  
HETATM 1135  O   HOH A 529      12.156 -11.491  21.809  1.00 13.04           O  
HETATM 1136  O   HOH A 530      -1.298  19.359   4.322  1.00 11.10           O  
HETATM 1137  O   HOH A 531      -7.147  -2.551   3.677  1.00 15.56           O  
HETATM 1138  O   HOH A 532      16.789  -1.198   5.753  1.00 18.85           O  
HETATM 1139  O   HOH A 533      -2.375  -9.144   7.093  1.00 24.28           O  
HETATM 1140  O   HOH A 534      18.643  -3.819  21.768  1.00 12.47           O  
HETATM 1141  O   HOH A 535      16.064   4.321  10.322  0.50 16.57           O  
HETATM 1142  O   HOH A 536      -3.254  23.330   4.336  1.00 24.04           O  
HETATM 1143  O   HOH A 537       0.764  17.989   3.099  1.00 17.93           O  
HETATM 1144  O   HOH A 538       7.193 -10.170  26.042  1.00 30.59           O  
HETATM 1145  O   HOH A 539      -8.941  13.974   7.784  1.00 33.35           O  
HETATM 1146  O   HOH A 540      13.370 -18.355  14.170  0.50  5.22           O  
HETATM 1147  O   HOH A 541       7.513  -2.676  -3.002  1.00 18.05           O  
HETATM 1148  O   HOH A 542       2.276  19.247   9.390  1.00 13.98           O  
HETATM 1149  O   HOH A 543       6.427  15.256   2.040  1.00 28.06           O  
HETATM 1150  O   HOH A 544       6.954  -2.960  -0.159  1.00 18.03           O  
HETATM 1151  O   HOH A 545       3.620 -11.195  18.225  1.00 28.84           O  
HETATM 1152  O   HOH A 546      14.740 -18.848  11.676  1.00 15.97           O  
HETATM 1153  O   HOH A 547      -6.661   2.670   7.060  1.00 17.34           O  
HETATM 1154  O   HOH A 548      17.522 -14.053  17.160  1.00 19.64           O  
HETATM 1155  O   HOH A 549       8.187  -0.493   0.619  1.00 12.97           O  
HETATM 1156  O   HOH A 550     -10.400  10.102  15.019  1.00 13.19           O  
HETATM 1157  O   HOH A 551      20.220   1.412  15.494  0.50  8.48           O  
HETATM 1158  O   HOH A 552      24.193 -13.521  13.231  1.00 10.65           O  
HETATM 1159  O   HOH A 553      -6.884  17.060  20.199  1.00 13.16           O  
HETATM 1160  O   HOH A 554      10.260  -9.620  24.867  1.00 20.31           O  
HETATM 1161  O   HOH A 555      16.140   6.540  23.555  1.00 12.20           O  
HETATM 1162  O   HOH A 556       6.685  -0.921  31.873  1.00 13.18           O  
HETATM 1163  O   HOH A 557       8.662  11.612  13.345  1.00 26.25           O  
HETATM 1164  O   HOH A 558      13.078 -18.260  23.012  1.00 18.52           O  
HETATM 1165  O   HOH A 559       6.293  -6.469  28.220  1.00 18.30           O  
HETATM 1166  O   HOH A 560       1.931  11.101  27.062  1.00 29.65           O  
HETATM 1167  O   HOH A 561       9.342 -17.984  20.186  1.00 25.17           O  
HETATM 1168  O   HOH A 562      13.000 -17.359   6.356  0.50 20.94           O  
HETATM 1169  O   HOH A 563      21.008  -2.917  22.171  1.00 38.34           O  
HETATM 1170  O   HOH A 564       8.884 -21.701   7.706  0.50 18.94           O  
HETATM 1171  O   HOH A 565      -7.503   4.274  23.946  1.00 14.57           O  
HETATM 1172  O   HOH A 566      10.590 -20.773  13.666  0.50 14.44           O  
HETATM 1173  O   HOH A 567      10.486   8.591  13.739  1.00 27.85           O  
HETATM 1174  O   HOH A 568      22.476  -1.635  12.738  1.00 19.57           O  
HETATM 1175  O   HOH A 569      14.072  -7.671  26.279  1.00 13.85           O  
HETATM 1176  O   HOH A 570      11.556   8.240   7.471  1.00 11.31           O  
HETATM 1177  O   HOH A 571     -11.712   8.476  16.996  1.00 12.40           O  
HETATM 1178  O   HOH A 572       2.862 -13.083   6.850  1.00 14.40           O  
HETATM 1179  O   HOH A 573      10.393   9.849   9.443  1.00 12.96           O  
HETATM 1180  O   HOH A 574      -3.259  -7.574  12.179  1.00 13.02           O  
HETATM 1181  O   HOH A 575      -8.253   8.651  11.665  1.00 15.19           O  
HETATM 1182  O   HOH A 576      -0.529  -9.697   8.787  1.00 25.93           O  
HETATM 1183  O   HOH A 577       9.936 -11.746  23.275  1.00 14.06           O  
HETATM 1184  O   HOH A 578       7.284  -9.000  -1.317  1.00 17.83           O  
HETATM 1185  O   HOH A 579      -4.896   0.322  25.308  1.00 15.78           O  
HETATM 1186  O   HOH A 580       5.255   7.258   3.193  1.00 12.68           O  
HETATM 1187  O   HOH A 581       2.757 -10.214  22.815  1.00 21.23           O  
HETATM 1188  O   HOH A 582       4.555  18.368   8.684  1.00 16.73           O  
HETATM 1189  O   HOH A 583       4.623 -14.997   6.193  1.00 20.08           O  
HETATM 1190  O   HOH A 584       2.824   3.672  29.902  1.00 17.92           O  
HETATM 1191  O   HOH A 585      14.830 -20.176  22.670  1.00 18.10           O  
HETATM 1192  O   HOH A 586       5.318   3.146  30.588  1.00 19.38           O  
HETATM 1193  O   HOH A 587      17.729   4.370  19.157  1.00 23.55           O  
HETATM 1194  O   HOH A 588      -5.715   4.811  18.976  1.00 21.01           O  
HETATM 1195  O   HOH A 589      -6.694   2.278  25.565  1.00 24.89           O  
HETATM 1196  O   HOH A 590      21.966 -18.850   9.984  1.00 18.32           O  
HETATM 1197  O   HOH A 591      -0.655  22.053   8.709  1.00 23.72           O  
HETATM 1198  O   HOH A 592       6.030  14.771  24.824  1.00 23.45           O  
HETATM 1199  O   HOH A 593       8.997   8.925  11.620  1.00 24.12           O  
HETATM 1200  O   HOH A 594       9.045  -1.059  32.941  1.00 24.16           O  
HETATM 1201  O   HOH A 595      -6.121  -4.195  10.747  1.00 22.61           O  
HETATM 1202  O   HOH A 596       5.764  10.112  -1.886  1.00 22.10           O  
HETATM 1203  O   HOH A 597       1.238  16.739  16.080  0.50 13.31           O  
HETATM 1204  O   HOH A 598      13.262   0.530  28.931  0.50 14.82           O  
HETATM 1205  O   HOH A 599       2.292   6.982  26.520  1.00 27.29           O  
HETATM 1206  O   HOH A 600       0.035  14.634   3.141  1.00 33.10           O  
HETATM 1207  O   HOH A 601       4.632   7.579  -2.327  1.00 20.95           O  
HETATM 1208  O   HOH A 602      -0.202   7.978  26.303  1.00 24.51           O  
HETATM 1209  O   HOH A 603      -5.537  -6.105  12.450  1.00 20.84           O  
HETATM 1210  O   HOH A 604       5.734   6.518  10.543  1.00 21.03           O  
HETATM 1211  O   HOH A 605      12.484   2.436   5.070  1.00 23.37           O  
HETATM 1212  O   HOH A 606      22.455  -9.683  12.901  1.00 25.34           O  
HETATM 1213  O   HOH A 607      17.683 -11.618  17.676  1.00 25.83           O  
HETATM 1214  O   HOH A 608      -8.572   2.609  22.287  1.00 24.78           O  
HETATM 1215  O   HOH A 609       2.901  19.960   7.268  1.00 38.43           O  
HETATM 1216  O   HOH A 610      15.448 -13.821   6.739  0.50 13.38           O  
HETATM 1217  O   HOH A 611      -7.325  17.393  11.037  1.00 19.72           O  
HETATM 1218  O   HOH A 612     -10.810   2.232  16.365  1.00 27.37           O  
HETATM 1219  O   HOH A 613       5.195 -13.135  16.941  1.00 23.89           O  
HETATM 1220  O   HOH A 614       1.305 -12.002   8.800  1.00 11.84           O  
HETATM 1221  O   HOH A 615       5.780   1.446  32.723  1.00 17.36           O  
HETATM 1222  O   HOH A 616     -11.190   4.575  19.287  1.00 24.17           O  
HETATM 1223  O   HOH A 617      -4.439 -15.231  11.938  1.00 20.61           O  
HETATM 1224  O   HOH A 618      -4.369  17.811  13.953  1.00 29.41           O  
HETATM 1225  O   HOH A 619       7.664 -22.105  15.590  1.00 28.69           O  
HETATM 1226  O   HOH A 620      19.333   3.675  16.113  0.50 22.71           O  
HETATM 1227  O   HOH A 621      19.729 -13.723  17.712  1.00 21.20           O  
HETATM 1228  O   HOH A 622      -4.503   7.339  28.669  1.00 29.12           O  
HETATM 1229  O   HOH A 623      -6.135   8.856  27.213  1.00 24.03           O  
HETATM 1230  O   HOH A 624      15.565 -12.361   4.127  1.00 31.78           O  
HETATM 1231  O   HOH A 625       7.149 -11.337   2.315  1.00 25.32           O  
HETATM 1232  O   HOH A 626     -11.039   3.064  24.223  1.00 28.95           O  
HETATM 1233  O   HOH A 627      -3.375 -16.183   9.656  1.00 26.31           O  
HETATM 1234  O   HOH A 628      -5.395  19.173  11.341  1.00 24.12           O  
HETATM 1235  O   HOH A 629      22.549  -5.056  20.428  1.00 30.95           O  
HETATM 1236  O   HOH A 630       4.970 -21.589  16.160  1.00 31.08           O  
HETATM 1237  O   HOH A 631       9.427  13.177   6.163  1.00 30.83           O  
HETATM 1238  O   HOH A 632      12.947   2.580  28.151  0.50 20.58           O  
HETATM 1239  O   HOH A 633      -7.196 -16.171  11.484  1.00 24.96           O  
HETATM 1240  O   HOH A 634       1.127   2.342  32.088  1.00 29.79           O  
HETATM 1241  O   HOH A 635      19.396  -2.032  27.952  1.00 29.91           O  
HETATM 1242  O   HOH A 636      -1.983 -12.988   5.465  1.00 31.10           O  
HETATM 1243  O   HOH A 637       8.084 -15.018  22.622  1.00 33.92           O  
HETATM 1244  O   HOH A 638      -8.982  15.315  10.035  0.50 12.22           O  
HETATM 1245  O   HOH A 639      10.766 -22.251  11.473  0.50 17.61           O  
HETATM 1246  O   HOH A 640      -3.162  -9.766  10.034  1.00 31.39           O  
HETATM 1247  O   HOH A 641     -12.230  16.784  10.327  0.50 19.04           O  
HETATM 1248  O   HOH A 642      12.283   0.134   3.191  0.50 18.63           O  
HETATM 1249  O   HOH A 643       6.859 -14.002   4.209  1.00 34.21           O  
HETATM 1250  O   HOH A 644      -8.358   8.592   4.476  1.00 26.67           O  
HETATM 1251  O   HOH A 645      -5.900  22.345   7.943  0.50 21.04           O  
HETATM 1252  O   HOH A 646      -8.627  12.527  10.213  1.00 39.47           O  
HETATM 1253  O   HOH A 647      16.146  -4.867   3.920  1.00 34.84           O  
HETATM 1254  O   HOH A 648      -8.664   4.656   9.092  1.00 25.42           O  
HETATM 1255  O   HOH A 649       9.019  10.916  15.873  1.00 34.35           O  
HETATM 1256  O   HOH A 650      10.452 -21.451   9.187  0.50 14.70           O  
HETATM 1257  O   HOH A 651      -5.913  20.823   8.244  0.50 10.02           O  
HETATM 1258  O   HOH A 652      13.067  -8.806   2.580  0.50 16.71           O  
HETATM 1259  O   HOH A 653      14.931   2.149   5.925  0.50 18.95           O  
HETATM 1260  O   HOH A 654      -4.017  -2.147  24.259  0.50 14.70           O  
HETATM 1261  O   HOH A 655       0.983 -13.621  18.211  0.50 23.46           O  
HETATM 1262  O   HOH A 656      -6.585   1.335   9.299  0.50 18.80           O  
HETATM 1263  O   HOH A 657       6.779  16.240  20.696  1.00 33.54           O  
HETATM 1264  O   HOH A 658      20.717   2.508  16.331  0.50 12.90           O  
HETATM 1265  O   HOH A 659      -8.691   3.294  20.104  1.00 23.50           O  
HETATM 1266  O   HOH A 660      14.927  -9.918   3.346  1.00 27.86           O  
HETATM 1267  O   HOH A 661      21.810  -9.336  17.453  1.00 42.67           O  
HETATM 1268  O   HOH A 662      19.406  -2.562  25.026  1.00 30.58           O  
HETATM 1269  O   HOH A 663      12.236  11.359  10.616  1.00 30.28           O  
HETATM 1270  O   HOH A 664      -2.948 -10.693   4.788  1.00 27.92           O  
HETATM 1271  O   HOH A 665      -2.341  19.906  13.632  1.00 33.38           O  
HETATM 1272  O   HOH A 666      -6.740  -5.072   4.949  1.00 27.26           O  
HETATM 1273  O   HOH A 667      19.805  -0.808   5.783  1.00 32.34           O  
HETATM 1274  O   HOH A 668      20.312 -10.901  18.218  1.00 34.11           O  
HETATM 1275  O   HOH A 669       3.855 -10.369  20.350  1.00 26.35           O  
HETATM 1276  O   HOH A 670      -2.575  14.632  23.458  0.50 21.30           O  
HETATM 1277  O   HOH A 671      20.882 -10.454  20.495  1.00 41.29           O  
HETATM 1278  O   HOH A 672      10.353  11.091   0.805  1.00 31.38           O  
HETATM 1279  O   HOH A 673       9.927   2.902   0.090  1.00 29.78           O  
HETATM 1280  O   HOH A 674       7.526   1.965  34.888  1.00 44.07           O  
HETATM 1281  O   HOH A 675       9.361   3.348  -2.735  1.00 40.33           O  
HETATM 1282  O   HOH A 676       4.842  -5.973  30.669  1.00 40.21           O  
HETATM 1283  O   HOH A 677       2.608   0.722  33.714  1.00 53.32           O  
HETATM 1284  O   HOH A 678      12.713  -8.828  28.410  1.00 40.06           O  
HETATM 1285  O   HOH A 679      -1.967   0.554  29.936  1.00 47.21           O  
HETATM 1286  O   HOH A 680      -8.910  -3.620  19.248  1.00 46.49           O  
HETATM 1287  O   HOH A 681      13.157   9.839  21.098  1.00 36.83           O  
HETATM 1288  O   HOH A 682       8.181 -23.326  13.399  1.00 34.60           O  
HETATM 1289  O   HOH A 683      16.971  -8.710   4.286  1.00 44.28           O  
HETATM 1290  O   HOH A 684      -6.875  -6.232   6.927  1.00 41.30           O  
HETATM 1291  O   HOH A 685      14.234 -22.909  21.792  1.00 43.63           O  
HETATM 1292  O   HOH A 686      18.550 -13.438   3.991  0.50 22.45           O  
HETATM 1293  O   HOH A 687       8.536  -8.311  29.242  1.00 42.58           O  
HETATM 1294  O   HOH A 688     -13.017  10.367  13.937  0.50 21.14           O  
HETATM 1295  O   HOH A 689      -5.084   4.770  29.163  1.00 34.64           O  
HETATM 1296  O   HOH A 690      25.614  -6.424  13.067  1.00 40.01           O  
HETATM 1297  O   HOH A 691       1.904  14.703  23.193  1.00 47.62           O  
HETATM 1298  O   HOH A 692      11.143 -22.470  22.670  1.00 44.30           O  
HETATM 1299  O   HOH A 693      -6.890  -2.160  18.089  1.00 22.01           O  
HETATM 1300  O   HOH A 694       6.681  -5.390   0.587  0.50 18.38           O  
HETATM 1301  O   HOH A 695       9.303  -3.532  34.116  1.00 37.06           O  
HETATM 1302  O   HOH A 696      18.038  -3.517  26.856  1.00 33.66           O  
HETATM 1303  O   HOH A 697       2.991  -3.436  31.272  1.00 41.43           O  
HETATM 1304  O   HOH A 698      -7.264  21.305   6.450  1.00 40.06           O  
HETATM 1305  O   HOH A 700      13.504 -21.039  14.836  1.00 40.39           O  
HETATM 1306  O   HOH A 702      24.810  -9.278  13.618  1.00 39.75           O  
HETATM 1307  O   HOH A 703      -5.362   1.532  -6.375  1.00 38.15           O  
HETATM 1308  O   HOH A 705      16.785  -5.735  28.372  1.00 37.00           O  
CONECT    1    2    3    4                                                      
CONECT    2    1                                                                
CONECT    3    1                                                                
CONECT    4    1    5                                                           
CONECT    5    4    6    8                                                      
CONECT    6    5    7   10                                                      
CONECT    7    6                                                                
CONECT    8    5    9                                                           
CONECT    9    8                                                                
CONECT   10    6                                                                
CONECT  730 1064                                                                
CONECT 1062 1063 1064                                                           
CONECT 1063 1062 1064                                                           
CONECT 1064  730 1062 1063 1069                                                 
CONECT 1064 1080 1088 1096                                                      
CONECT 1065 1070 1100                                                           
CONECT 1066 1073 1081                                                           
CONECT 1067 1084 1089                                                           
CONECT 1068 1092 1097                                                           
CONECT 1069 1064 1070 1073                                                      
CONECT 1070 1065 1069 1071                                                      
CONECT 1071 1070 1072 1075                                                      
CONECT 1072 1071 1073 1074                                                      
CONECT 1073 1066 1069 1072                                                      
CONECT 1074 1072                                                                
CONECT 1075 1071 1076                                                           
CONECT 1076 1075 1077                                                           
CONECT 1077 1076 1078 1079                                                      
CONECT 1078 1077                                                                
CONECT 1079 1077                                                                
CONECT 1080 1064 1081 1084                                                      
CONECT 1081 1066 1080 1082                                                      
CONECT 1082 1081 1083 1085                                                      
CONECT 1083 1082 1084 1086                                                      
CONECT 1084 1067 1080 1083                                                      
CONECT 1085 1082                                                                
CONECT 1086 1083 1087                                                           
CONECT 1087 1086                                                                
CONECT 1088 1064 1089 1092                                                      
CONECT 1089 1067 1088 1090                                                      
CONECT 1090 1089 1091 1093                                                      
CONECT 1091 1090 1092 1094                                                      
CONECT 1092 1068 1088 1091                                                      
CONECT 1093 1090                                                                
CONECT 1094 1091 1095                                                           
CONECT 1095 1094                                                                
CONECT 1096 1064 1097 1100                                                      
CONECT 1097 1068 1096 1098                                                      
CONECT 1098 1097 1099 1101                                                      
CONECT 1099 1098 1100 1102                                                      
CONECT 1100 1065 1096 1099                                                      
CONECT 1101 1098                                                                
CONECT 1102 1099 1103                                                           
CONECT 1103 1102 1104                                                           
CONECT 1104 1103 1105 1106                                                      
CONECT 1105 1104                                                                
CONECT 1106 1104                                                                
MASTER      264    0    3    8    0    0    6    6 1307    1   57   11          
END                                                                             
"""