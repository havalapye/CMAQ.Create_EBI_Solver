       SUBROUTINE WR_GP1

C**********************************************************************
C
C  FUNCTION: Create source code for the hrgp1 subroutine in EBI
C
C  PRECONDITIONS: None
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by Jerry Gipson, February, 2004
C
C**********************************************************************
      USE ENV_VARS
      USE GLOBAL_DATA
      USE M3UTILIO ! IOAPI parameters and declarations

      IMPLICIT NONE

C..INCLUDES: 
!      INCLUDE SUBST_IOPARMS        ! IOAPI parameters
!      INCLUDE SUBST_IODECL         ! IOAPI declarations
      INCLUDE SUBST_RXCMMN         ! Mechanism data
      
C..ARGUMENTS: None

C..PARAMETERS:
      INTEGER, PARAMETER   ::  GRPNO = 1

C..EXTERNAL FUNCTIONS:
!      INTEGER   JUNIT      ! gets unit no.
!      INTEGER   INDEX1     ! find position of string in list

C..SAVED LOCAL VARIABLES: None
 
C..SCRATCH LOCAL VARIABLES:
      CHARACTER(  16 )  ::    PNAME = 'WR_GP1'     ! Program name
      CHARACTER( 256 )  ::    MSG                  ! Message text
      CHARACTER( 100 )  ::    LINEIN               ! Input line
      CHARACTER(  CL )  ::    SPOUT                ! Ouput species
      CHARACTER(  16 )  ::    SPEC     
      CHARACTER( 256 )  ::    FNAME                ! Name of file to open
      CHARACTER(  72 )  ::    CLINE                ! Line of c's
      CHARACTER( 100 )  ::    LINOUT
      CHARACTER( 150 )  ::    RXOUT
      CHARACTER( 100 )  ::    BLANK_LINE
      CHARACTER*(  3 )  ::    RNUM                 ! Reaction number
      CHARACTER*(  9 )  ::    COUT                 ! Output coefficient
      CHARACTER*(  1 )  ::    SGN                  ! Coefficient sign
   

      INTEGER  :: E1, E2       ! end pos of string
      INTEGER  :: IND          ! array index
      INTEGER  :: IIN          ! Unit no. of input file
      INTEGER  :: IOUT         ! Unit no. of output file
      INTEGER  :: LOGDEV       ! Unit no. of logdev
      INTEGER  :: N, S, P, R   ! Loop indices
      INTEGER  :: NR           ! No. of reactants
      INTEGER  :: NPOS         ! Reaction index
      INTEGER  :: RPOS1        ! Species to occupy reactant pos 1 in rxn line
      INTEGER  :: RPOS2        ! Species to occupy reactant pos 2 in rxn line
      INTEGER  :: PPOS1        ! Species to occupy product pos 1 in rxn line
      INTEGER  :: PPOS2        ! Species to occupy product pos 2 in rxn line

      INTEGER  :: J1, J2, K1_3 ! Rxn nos for NO2+hv, O3P+NO, & NO+O3
      INTEGER  :: KO3_O1D      ! Rxn number for O3+hv=O1D
      INTEGER  :: KNO2_NO2EX   ! Rxn number for NO2+hv=NO2EX

      LOGICAL  :: LPHOT        ! Photolysis rxn flag
      LOGICAL  :: LFIRST       ! First pass flag
      LOGICAL  :: LRXN1        ! First rxn flag
      LOGICAL  :: LNO2EX_DONE  ! Flag to indicate NO2EX done

      REAL     :: COEFF        ! Prod/loss coefficient
      REAL     :: RNO          ! Sum of NO  reactant coefficients
      REAL     :: RNO2         ! Sum of NO2 reactant coefficients
      REAL     :: PNO          ! Sum of NO  product  coefficients
      REAL     :: PNO2         ! Sum of NO2 product  coefficients

      REAL     :: RO3          ! Sum of O3  reactant coefficients
      REAL     :: PO3          ! Sum of O3  product  coefficients

      REAL     :: RO3P         ! Sum of O3P reactant coefficients
      REAL     :: PO3P         ! Sum of O3P product  coefficients

      REAL     :: RO1D         ! Sum of O1D reactant coefficients
      REAL     :: PO1D         ! Sum of O1D product  coefficients

      

C**********************************************************************

      DO N = 1, 72
        CLINE( N : N ) = 'c'
      END DO

      DO N = 1, 100
        BLANK_LINE( N : N ) = ' '
      END DO

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Open ouput file and code template 
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      LOGDEV = INIT3()

      E1 = LEN_TRIM( OUTPATH )

      FNAME = OUTPATH( 1 : E1 ) // '/hrg1.F' 

      IOUT = JUNIT()

      OPEN( UNIT = IOUT, FILE = FNAME, ERR = 9000 )


      IIN = JUNIT()

      E1 = LEN_TRIM( TMPLPATH )

      FNAME = TMPLPATH( 1 : E1 ) // '/hrg1.F' 

      OPEN( UNIT = IIN, FILE = FNAME, ERR = 9000 )


      IF( LWR_COPY ) CALL WR_COPYRT( IOUT )

      IF( LWR_CVS_HDR ) CALL WR_CVSHDR( IOUT )

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Read, modify, and write 1st section of code from template
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

  100 CONTINUE

      READ( IIN, 92000, END = 1000 ) LINEIN

      IF( LINEIN( 1 : 2 ) .EQ. 'R1' ) THEN

         WRITE( IOUT, 93000 ) GC_TAG( 1 : LEN_TRIM( GC_TAG ) )

         GO TO 100

      ELSEIF( LINEIN( 1 : 2 ) .EQ. 'R2' ) THEN

         WRITE( IOUT, 93020 ) CR_DATE( 1 : LEN_TRIM( CR_DATE ) )

         GO TO 100
            

      ELSEIF( LINEIN( 1 : 2 ) .EQ. 'S1' ) THEN

         GO TO 1000

      ELSE

         WRITE( IOUT, 92000 ) LINEIN( 1 : LEN_TRIM( LINEIN ) )

         GO TO 100

      END IF

 1000 CONTINUE

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Do O1D section
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      WRITE( IOUT, 92020 )
      WRITE( IOUT, 92000 ) CLINE
      WRITE( IOUT, 93100 )
      WRITE( IOUT, 92000 ) CLINE

c..get all reactions in which O1D is reacting
      LRXN1 = .TRUE.
      DO N = 1, NRXNS

         IF ( IRR( N, 1 ) .NE. O1D ) CYCLE   ! Skip Rxns w/ Lo1d=0

         COEFF = 1.0

         NPOS  = 20
         RPOS1 = O1D
         RPOS2 = 0
         PPOS1 = 0
         PPOS2 = 0
         CALL BLD_OUTLINE( 'LFREQ', 'O1D_S', 'O1D', O1D, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO

      WRITE( IOUT, 92000 )

c..get reaction(s) producing O3P from O1D
      LRXN1 = .TRUE.
      DO N = 1, NRXNS

         IF ( IRR( N, 1 ) .NE. O1D .OR. IRR( N, 4 ) .NE. O3P ) CYCLE 

         COEFF = SC( N, 1 )

         NPOS  = 20
         RPOS1 = O1D
         RPOS2 = 0
         PPOS1 = OH
         PPOS2 = 0
         CALL BLD_OUTLINE( 'LFREQ', 'O3P_S', 'O1D', O1D, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO

c..write the the final line 
      WRITE( IOUT, 92000 )
      LINOUT = '      O3P_S  = O3P_S / O1D_S'
      E1 = LEN_TRIM( LINOUT )
      WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Do NO2EX section if included in Group 1
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF( LNO2EX_CYCLE ) THEN
        
         WRITE( IOUT, 92020 )
         WRITE( IOUT, 92000 ) CLINE
         WRITE( IOUT, 93200 )
         WRITE( IOUT, 92000 ) CLINE

c..get all reactions in which NO2EX is reacting
         LRXN1 = .TRUE.
         DO N = 1, NRXNS

            IF ( IRR( N, 1 ) .NE. NO2EX ) CYCLE   ! Skip Rxns w/ Lno2ex=0

            COEFF = 1.0

            NPOS  = 20
            RPOS1 = NO2EX
            RPOS2 = 0
            PPOS1 = 0
            PPOS2 = 0
            CALL BLD_OUTLINE( 'LFREQ', 'EXN_S', 'NO2EX', NO2EX, COEFF, N, GRPNO,  
     &           NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

            LRXN1 = .FALSE.

            E1 = LEN_TRIM( LINOUT )
            WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

         END DO  

         WRITE( IOUT, 92000 )

c..get reaction(s) producing NO2 from NO2EX
         LRXN1 = .TRUE.
         DO N = 1, NRXNS

            IF ( IRR( N, 1 ) .NE. NO2EX .OR. IRR( N, 4 ) .NE. NO2 ) CYCLE 

            COEFF = SC( N, 1 )

            NPOS  = 20
            RPOS1 = NO2EX
            RPOS2 = 0
            PPOS1 = NO2
            PPOS2 = 0
            CALL BLD_OUTLINE( 'LFREQ', 'NO2_S', 'NO2EX', NO2EX, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

            LRXN1 = .FALSE.

            E1 = LEN_TRIM( LINOUT )
            WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

         END DO

c..write the the final line 
         WRITE( IOUT, 92000 )
         LINOUT = '      NO2_S  = NO2_S / EXN_S'
         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

       END IF  ! LNO2EX_CYCLE = .TRUE.



cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  R1_2 computation ( Production of NO from reactions of NO2 )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C    R1_2 includes the following NO loss/NO2 production terms:    
c      a) those in which NO is produced from NO2 (include only
c         equivalent amounts of loss and production) 
c
c    Hence,
c
c   {aNO +} bNO2 {+ X} = cNO + dNO2
c      if c le a  ==> Pno = 0, so R1_2 coeff = 0
c      if c gt a  ==> Pno > 0 
c         if b le d ==> Lno2 = 0, so R1_2 coeff = 0
c         if b gt d ==> Lno2 > 0, so
c            if b-d > c-a ==> Lno2 > Pno, so R1_2 coeff = c-a
c            if b-d = c-a ==> Lno2 = Pno, so R1_2 coeff = c-a
c            if b-d < c-a ==> Lno2 < Pno, so R1_2 coeff = b-d
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c..Write the section header
      WRITE( IOUT, 92020 )
      WRITE( IOUT, 92000 ) CLINE
      WRITE( IOUT, 94000 )
      WRITE( IOUT, 92000 ) CLINE


      LRXN1 = .TRUE.
      DO N = 1, NRXNS

c..find the rxns to include and set the coefficient
         COEFF = 0.0
         CALL SUM_COEFF( RNO,   'R', NO,   N )
         CALL SUM_COEFF( RNO2,  'R', NO2,  N )
         CALL SUM_COEFF( PNO,   'P', NO,   N )
         CALL SUM_COEFF( PNO2,  'P', NO2,  N )

         IF( PNO  .LE. RNO  ) CYCLE             ! Skip rxn if Pno=0 

         IF( RNO2 .LE. PNO2 ) CYCLE             ! Skip rxn if Lno2=0

         IF( RNO2 - PNO2 .GE. PNO - RNO ) THEN    
            COEFF = PNO - RNO                   ! for Lno2 >= Pno
         ELSE
            COEFF = RNO2 - PNO2                 ! for Lno2 < Pno
         END IF

         IF( COEFF .EQ. 0.0 ) CYCLE

c..call routine to create output line & write it
         NPOS = 20
         RPOS1 = NO2
         RPOS2 = 0
         PPOS1 = NO
         PPOS2 = NO2
         CALL BLD_OUTLINE( 'LFREQ', 'R1_2', 'NO2', NO2, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO  

      WRITE( IOUT, '( A )' ) '      R1_2  = R1_2 * DTC'

   
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  P1 computation ( Production of NO )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C    P1 includes NO production terms from the following reactions:    
c      a) those in which NO is produced & NO2 is NOT a reactant
c      b) those in which NO is produced and NO2 is consumed and the 
c         NO production rate exceeds the NO2 loss rate (excess amount only)
c
c    Hence,
c
c    {aNO +} bNO2 {+ X} = cNO + dNO2
c      if c le a  ==> Pno=o, so P1 coeff = 0 
c      if c gt a  ==> Pno > 0, so
c         if b le d  ==> Lno2 = 0, so P1 coeff = c-a
c         if b gt d  ==> Lno2 > 0, so
c            if b-d > c-a ==> Lno2 > Pno, so P1 coeff = 0
c            if b-d = c-a ==> Lno2 = Pno, so P1 coeff = 0
c            if b-d < c-a ==> Lno2 < Pno, so P1 coeff = (c-a) - (b-d)
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      WRITE( IOUT, 92020 )
      LRXN1 = .TRUE.
 
      DO N = 1, NRXNS

c..Determine the reaction to include & get the coefficient for the prod term
         COEFF = 0.0
         CALL SUM_COEFF( RNO,  'R', NO,   N )
         CALL SUM_COEFF( RNO2, 'R', NO2,  N )
         CALL SUM_COEFF( PNO,  'P', NO,   N )
         CALL SUM_COEFF( PNO2, 'P', NO2,  N )

         IF( PNO .LE. RNO ) CYCLE                     ! Skip rxns w/ Pno=0

         IF( RNO2 .LE. PNO2 ) THEN               
            COEFF = PNO - RNO                         ! Rxns w/ Lno2=0
         ELSEIF( RNO2 - PNO2 .LT. PNO - RNO ) THEN
            COEFF = ( PNO - RNO ) - ( RNO2 - PNO2 )   ! Rxns w/ Lno2 < Pno
         END IF

         IF( COEFF .EQ. 0.0 ) CYCLE     

    

c..call routine to create output line & write it
         NPOS = 25
         RPOS1 = NO2
         RPOS2 = 0
         PPOS1 = NO
         PPOS2 = NO2
         CALL BLD_OUTLINE( 'RXRAT', 'P1', '   ', 0, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO

      SPOUT = ADJUSTL( GC_SPC( NO ) )
      E1 = LEN_TRIM( SPOUT )
      WRITE( IOUT, '( 3A )' ) '      P1    = YC0( ', SPOUT( 1 : E1 ),
     &       ' ) + P1 * DTC'



cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  L1 computation ( Loss of NO )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C    L1 includes the following net NO loss terms:
c      a) loss from reactions in which NO2 is not produced
c      b) in reactions in which NO2 is produced, the amount of NO lost
c         in excess of the amount of NO2 formed
c
c    Hence,
c
c    aNO {+ bNO2} {+ X} = cNO + dNO2
c      if a le c  ==> Lno = 0, so L1 coeff =0
c      if a gt c  ==> Lno > 0, so
c         if d le b  ==> Pno2 = 0 so L1 coeff = (a-c)
c         if d gt b  ==> Pno2 > 0, so 
c            if a-c le d-b  ==> Lno < Pno2, so L1 coeff = 0
c            if a-c gt d-b  ==> Lno > Pno2, so L1 coeff = (a-c)-(d-b)
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      WRITE( IOUT, 92020 )
      LRXN1 = .TRUE.
      DO N = 1, NRXNS         

c..Determine the rxn to include & get the coefficient for the loss term
         COEFF = 0.0
         CALL SUM_COEFF( RNO,  'R', NO,  N )
         CALL SUM_COEFF( RNO2, 'R', NO2, N )
         CALL SUM_COEFF( PNO2, 'P', NO2, N )
         CALL SUM_COEFF( PNO,  'P', NO,  N )

         IF( RNO .LE. PNO ) CYCLE                   ! Skip rxns w/ Lno=0

         IF( PNO2 .LE. RNO2 )   COEFF = RNO - PNO   ! Rxns w/ Lno>0 & Pno2=0

         IF( PNO2 .GT. RNO2 .AND. 
     &       RNO - PNO .GT. PNO2 - RNO2 ) 
     &     COEFF =  RNO - PNO - ( PNO2 - RNO2 )    ! Rxns w/ Lno>0 & Lno>Pno2
                                                     
         IF( COEFF .EQ. 0.0 ) CYCLE

c..call routine to create output line & write it
         NPOS  = 20
         RPOS1 = NO
         RPOS2 = 0
         PPOS1 = NO
         PPOS2 = NO2
         CALL BLD_OUTLINE( 'LFREQ', 'L1', 'NO', NO, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO
           
      LINOUT = '      L1    = 1.0 + L1 * DTC'
      E1 = LEN_TRIM( LINOUT )
      WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  R2_1 computation ( Production of NO2 from reactions of NO )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C    R2_1 includes NO2 production from the following reeactions:    
c      a) those in which NO2 is produced from NO (include only
c         equivalent amounts of loss and production)  
c      b) EXCEPTION: do not include NO+O3=NO2 
c
c    Hence,
c
c    aNO {bNO2} {+ X} = cNO + dNO2
c      if d le b  ==> Pno2 = 0, so R2_1 coeff = 0
c      if d gt b  ==> Pno2 > 0 
c         if a le c ==> Lno = 0, so R2_1 coeff = 0
c         if c gt a ==> Lno > 0, so
c            if d-b > a-c ==> Pno2 > Lno, so R2_1 coeff = a-c
c            if d-b = a-c ==> Pno2 = Lno, so R2_1 coeff = a-c
c            if d-b < a-c ==> Pno2 < Lno, so R2_1 coeff = d-b
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c..Write the section header
      WRITE( IOUT, 92020 )
      WRITE( IOUT, 92000 ) CLINE
      WRITE( IOUT, 94020 )
      WRITE( IOUT, 92000 ) CLINE

      LRXN1 = .TRUE.
      DO N = 1, NRXNS         

c..Determine the rxn to include & get the coefficient for the loss term
         COEFF = 0.0
         CALL SUM_COEFF( RNO,  'R', NO,  N )
         CALL SUM_COEFF( RNO2, 'R', NO2, N )
         CALL SUM_COEFF( PNO,  'P', NO,  N )
         CALL SUM_COEFF( PNO2, 'P', NO2, N )

         IF( PNO2 .LE. RNO2 ) CYCLE     ! Skip rxns with Pno2=0

c..do not include NO+O3=NO2 reaction
         IF( ( IRR( N, 1 ) .EQ. NO .AND. IRR( N, 2 ) .EQ. O3 ) .OR.
     &       ( IRR( N, 1 ) .EQ. O3 .AND. IRR( N, 2 ) .EQ. NO ) .AND.
     &         IRR( N, 4 ) .EQ. NO2 ) CYCLE

         IF( RNO .LE. PNO ) CYCLE      ! Skip rxns with Lno=0
             
         IF( PNO2 - RNO2 .GE. RNO - PNO ) THEN
            COEFF = RNO - PNO                   ! for Pno2>=Lno
         ELSE
            COEFF = PNO2 - RNO2                 ! for Pno2<Lno
         END IF

         IF( COEFF .EQ. 0.0 ) CYCLE

         
c..call routine to create output line & write it
         NPOS  = 20
         RPOS1 = NO
         RPOS2 = NO2
         PPOS1 = NO2
         PPOS2 = NO
         CALL BLD_OUTLINE( 'LFREQ', 'R2_1', 'NO', NO, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO
           
      LINOUT = '      R2_1  = R2_1 * DTC'
      E1 = LEN_TRIM( LINOUT )
      WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  P2 computation ( Production of NO2 )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c    P2 includes NO2 production terms from the following reactions:    
c      a) those in which NO2 is produced & NO is NOT a reactant
c      b) those in which NO2 is produced and NO is consumed and the 
c         NO2 production rate exceeds the NO loss rate (excess amount only)
c      c) E
c
c    Hence,
c
c    aNO + bNO2 {+ X} {+Y} = cNO + dNO2
c      if d le b  ==> Pno2=o, so P2 coeff = 0 
c      if d gt b  ==> Pno2 > 0, so
c         if a le c  ==> Lno = 0, so P2 coeff = d-b
c         if a gt c  ==> Lno > 0, so
c            if d-b > a-c ==> Pno2 > Lno, so P2 coeff = (d-b)-(a-c)
c            if d-b = a-c ==> Pno2 = Lno, so P2 coeff = 0
c            if d-b < a-c ==> Pno2 < Lno, so P2 coeff = 0
c
c    Added special treatment of NO2EX to group 1 - 
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      WRITE( IOUT, 92020 )
      LRXN1 = .TRUE.
      LNO2EX_DONE = .FALSE.

      DO N = 1, NRXNS

c..Determine the reaction to include & get the coefficient for the prod term
         COEFF = 0.0
         CALL SUM_COEFF( RNO,  'R', NO,   N )
         CALL SUM_COEFF( RNO2, 'R', NO2,  N )
         CALL SUM_COEFF( PNO,  'P', NO,   N )
         CALL SUM_COEFF( PNO2, 'P', NO2,  N )

c         ! do not include NO+O3=NO2 reaction
c         IF( ( IRR( N, 1 ) .EQ. NO .AND. IRR( N, 2 ) .EQ. O3 ) .OR.
c     &       ( IRR( N, 2 ) .EQ. NO .AND. IRR( N, 1 ) .EQ. O3 ) ) CYCLE

         IF( PNO2 .LE. RNO2 ) CYCLE                 ! Skip rxns with Pno2=0

         IF( RNO .LE. PNO )                         ! Rxns w/ Pno2>0 & Lno=0
     &       COEFF = PNO2 - RNO2                    

         IF( RNO - PNO .GT. 0.0 .AND.               ! Rxns w/ Pno2>0 & Lno>0 &
     &     PNO2 - RNO2 .GT. RNO - PNO )             ! Pno2>Lno   
     &     COEFF = ( PNO2 - RNO2 ) - ( RNO - PNO ) 

         IF( COEFF .EQ. 0.0 ) CYCLE      


c..only include 1 NO2EX-NO2 reaction ( multiple reactions accounted for in coeffs) 
         IF( LNO2EX_CYCLE .AND. LNO2EX_DONE .AND. 
     &     IRR( N, 1 ) .EQ. NO2EX .AND. IRR( N, 4 ) .EQ. NO2 ) CYCLE 
     

c..call routine to create output line & write it
         NPOS = 25
         RPOS1 = NO
         RPOS2 = NO2
         PPOS1 = NO2
         PPOS2 = NO
         CALL BLD_OUTLINE( 'RXRAT', 'P2', '   ', 0, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

         IF( LNO2EX_CYCLE .AND. 
     &     IRR( N, 1 ) .EQ. NO2EX .AND. IRR( N, 4 ) .EQ. NO2 ) 
     &     LNO2EX_DONE = .TRUE. 

      END DO

      SPOUT = ADJUSTL( GC_SPC( NO2 ) )
      E1 = LEN_TRIM( SPOUT )
      WRITE( IOUT, '( 3A )' ) '      P2 = YC0( ', SPOUT( 1 : E1 ),
     &       ' ) + P2 * DTC'

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  L2 computation ( Loss of NO2 )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  L2 includes the following NO2 loss terms:
c     a) for reactions in which NO is not produced, the amount of NO2 lost
c     b) for reactions in which NO2 is lost and NO is produced,
c        the amount of NO2 lost in excess of the amount of NO produced
c
c    Hence,
c
c    {aNO +} bNO2 {+ X} = cNO + dNO2
c      if b le d  ==> Lno2 = 0, so L2 coeff =0
c      if b gt d  ==> Lno2 > 0, so
c         if c le a  ==> Pno = 0 so L2 coeff = (a-c)
c         if c gt a  ==> Pno > 0, so 
c            if b-d le c-a  ==> Lno2 < Pno, so L2 coeff = 0
c            if b-d gt c-a  ==> Lno2 > Pno, so L2 coeff = (b-d)-(c-a)
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      WRITE( IOUT, 92020 )
      LRXN1 = .TRUE.
      DO N = 1, NRXNS         

c..Determine the rxn to include & get the coefficient for the loss term
         COEFF = 0.0
         CALL SUM_COEFF( RNO,  'R', NO,  N )
         CALL SUM_COEFF( RNO2, 'R', NO2, N )
         CALL SUM_COEFF( PNO,  'P', NO,  N )
         CALL SUM_COEFF( PNO2, 'P', NO2, N )

         IF( RNO2 .LE. PNO2 ) CYCLE                ! Skip rxns w/ Lno2=0

         IF( RNO .GE. PNO )  COEFF = RNO2 - PNO2   ! Rxns w/ Lno2>0 & Pno=0      
         IF( RNO .LT. PNO .AND.                    ! Rxns w/ Lno2>0 & Pno>0
     &       RNO2 - PNO2 .GT. PNO - RNO )          ! & Lno2>Pno
     &      COEFF = (RNO2 -PNO2 ) - ( PNO - RNO )  
                                                     
         IF( COEFF .EQ. 0.0 ) CYCLE

c..call routine to create output line & write it
         NPOS  = 20
         RPOS1 = NO2
         RPOS2 = NO
         PPOS1 = NO
         PPOS2 = NO2
         CALL BLD_OUTLINE( 'LFREQ', 'L2  ', 'NO2', NO2, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO
           
      LINOUT = '      L2     = 1.0 + L2 * DTC'
      E1 = LEN_TRIM( LINOUT )
      WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  P3 computation ( Production of O3 )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c    P3 includes O3 production terms from the following reactions:    
c      a) those in which O3 is produced EXCEPT O3P=O3
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c..Write the section header
      WRITE( IOUT, 92020 )
      WRITE( IOUT, 92000 ) CLINE
      WRITE( IOUT, 94040 )
      WRITE( IOUT, 92000 ) CLINE

      LRXN1 = .TRUE.
      DO N = 1, NRXNS

c..Determine the reaction to include & get the coefficient for the prod term
         COEFF = 0.0
         CALL SUM_COEFF( RO3, 'R', O3, N )
         CALL SUM_COEFF( PO3, 'P', O3, N )

         IF( RO3 .GE. PO3 ) CYCLE                 ! Skip rxns with Po3=0

         IF( IRR( N, 1 ) .EQ. O3P .AND. 
     &       IRR( N, 4 ) .EQ. O3 ) CYCLE          ! Skip O3P=O3 rxn

         COEFF = PO3           

c..call routine to create output line & write it
         NPOS = 25
         RPOS1 = 0
         RPOS2 = 0
         PPOS1 = O3
         PPOS2 = 0
         CALL BLD_OUTLINE( 'RXRAT', 'P3  ', '   ', 0, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO


      SPOUT = ADJUSTL( GC_SPC( O3 ) )
      E1 = LEN_TRIM( SPOUT )

      IF( LRXN1 ) THEN
          WRITE( IOUT, '( 3A )' ) '      P3 = YC0( ', SPOUT( 1 : E1 ),
     &       ' ) '         
      ELSE
         WRITE( IOUT, '( 3A )' )  '      P3 = YC0( ', SPOUT( 1 : E1 ),
     &       ' ) + P3 * DTC'
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  L3 computation ( Loss of O3 )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c    L3 includes O3 loss terms from the following reactions:    
c       a) those in which O3 is lost EXCEPT NO+O3=NO2
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      WRITE( IOUT, 92020 )
      LRXN1 = .TRUE.
      DO N = 1, NRXNS         

c..Determine the rxn to include & get the coefficient for the loss term
         COEFF = 0.0
         CALL SUM_COEFF( RO3,  'R', O3,  N )
         CALL SUM_COEFF( PO3,  'P', O3,  N )

         IF( PO3 .GE. RO3 ) CYCLE                ! Skip rxns w/ Lo3=0

         ! do not include NO+O3=NO2 reaction
         IF( ( IRR( N, 1 ) .EQ. NO .AND. IRR( N, 2 ) .EQ. O3 ) .OR.
     &       ( IRR( N, 1 ) .EQ. O3 .AND. IRR( N, 2 ) .EQ. NO ) .AND.
     &         IRR( N, 4 ) .EQ. NO2 ) CYCLE
                                                     
         COEFF = RO3

c..call routine to create output line & write it
         NPOS  = 20
         RPOS1 = O3
         RPOS2 = 0
         PPOS1 = 0
         PPOS2 = 0
         CALL BLD_OUTLINE( 'LFREQ', 'L3  ', 'O3', O3, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO
           
      LINOUT = '      L3    = 1.0 + L3 * DTC'
      E1 = LEN_TRIM( LINOUT )
      WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  P12 computation ( Production of O3P )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c    P12 includes O3P production terms from the following reactions:    
c      a) those in which O3P is produced EXCEPT NO2+hv=O3P
c      b) special conditions: eliminate O1D=O3P and change
c         O3=O1D to O3=O3P with stoichiometric coeff=O3P_S
c         ( done in BLD_OUTLINE)
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c..Write the section header
      WRITE( IOUT, 92020 )
      WRITE( IOUT, 92000 ) CLINE
      WRITE( IOUT, 94060 )
      WRITE( IOUT, 92000 ) CLINE

      LRXN1 = .TRUE.
      DO N = 1, NRXNS

         CALL SUM_COEFF( RO3P,  'R', O3P,  N )
         CALL SUM_COEFF( PO3P,  'P', O3P,  N )

          IF( RO3P .GT. 0 .AND. PO3P .EQ. RO3P ) THEN
             print*,'rxn = ',N,' Po3p = ',PO3P,' Ro3p = ',RO3P
             CYCLE                ! Skip rxns with Po3p=0
          END IF


c..Determine the reaction to include & get the coefficient for the prod term
         COEFF = 0.0
         CALL SUM_COEFF( PO3P, 'P', O3P, N )
         CALL SUM_COEFF( RO1D, 'R', O1D, N )
         CALL SUM_COEFF( PO1D, 'P', O1D, N )

         IF( PO3P .LE. 0.0 .AND. PO1D .LE. 0.0 ) CYCLE  ! Skip rxns with Po3p=0
                                                        ! & Po1d=0

         IF( IRR( N, 1 ) .EQ. O1D .AND.
     &       IRR( N, 4 ) .EQ. O3P ) CYCLE               ! Skip O1D=O3P  


      ! Skip NO2+hv=O3P rxn
         IF( IRR( N, 1 ) .EQ. NO2 .AND. ( IRR( N, 4 ) .EQ. O3P .OR.
     &       IRR( N, 5 ) .EQ. O3P ) ) CYCLE                            

         COEFF = PO3P           

c..call routine to create output line & write it
         NPOS = 25
         RPOS1 = 0
         RPOS2 = 0
         PPOS1 = O3P
         PPOS2 = 0

         CALL BLD_OUTLINE( 'RXRAT', 'P12 ', '   ', 0, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO


      SPOUT = ADJUSTL( GC_SPC( O3P ) )
      E1 = LEN_TRIM( SPOUT )

      WRITE( IOUT, '( 3A )' ) '      P12 = YC0( ', SPOUT( 1 : E1 ),
     &       ' ) + P12 * DTC'

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  L12 computation ( Loss of O3P )
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c    L12 includes O3P loss terms from the following reactions:    
c       a) those in which O3P reacts 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c..Write the section header
      WRITE( IOUT, 92020 )

      LRXN1 = .TRUE.
      DO N = 1, NRXNS

c..Determine the reaction to include & get the coefficient for the prod term
         COEFF = 0.0
         CALL SUM_COEFF( RO3P, 'R', O3P, N )
         CALL SUM_COEFF( PO3P, 'P', O3P, N )

         IF( PO3P .GE. RO3P ) CYCLE                     ! Skip rxns with Lo3p=0

         COEFF = RO3P - PO3P

c..call routine to create output line & write it
         NPOS  = 25
         RPOS1 = O3P
         RPOS2 = 0
         PPOS1 = O3P
         PPOS2 = 0

         CALL BLD_OUTLINE( 'LFREQ', 'L12 ', 'O3P', O3P, COEFF, N, GRPNO,  
     &        NPOS, LINOUT, LRXN1, RPOS1, RPOS2, PPOS1, PPOS2 )

         LRXN1 = .FALSE.

         E1 = LEN_TRIM( LINOUT )
         WRITE( IOUT, 92000 ) LINOUT( 1 : E1 )

      END DO

      WRITE( IOUT, '( 3A )' ) '      L12   = 1.0 + L12 * DTC'


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Continue reading template section
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

  200 CONTINUE

      READ( IIN, 92000, END = 300 ) LINEIN

      IF( LINEIN( 1 : 2 ) .EQ. 'S1' ) GO TO 300

      GO TO 200

  300 CONTINUE

c..Find rection numbers for NO2->NO+O3P, O3P->O3, & NO+O3->NO2
      DO N = 1, NRXNS

         IF( NREACT( N ) .EQ. 1 .AND. IRR( N, 1 ) .EQ. NO2 ) THEN
            IF( IRR( N, 4 ) .EQ. NO  .AND. IRR( N, 5 ) .EQ. O3P .OR.
     &          IRR( N, 4 ) .EQ. O3P .AND. IRR( N, 5 ) .EQ. NO ) 
     &          J1 = N
         END IF

         IF( IRR( N, 1 ) .EQ. O3P .AND. IRR( N, 4 ) .EQ. O3  )
     &      J2 = N

         IF( ( IRR( N, 1 ) .EQ. NO .AND. IRR( N, 2 ) .EQ. O3  ) .OR.
     &       ( IRR( N, 1 ) .EQ. O3 .AND. IRR( N, 2 ) .EQ. NO ) ) 
     &      K1_3 = N

      END DO

      LFIRST = .TRUE.

  400 CONTINUE

      READ( IIN, 92000, END = 2000 ) LINEIN

      IF( LINEIN( 1 : 2 ) .EQ. 'R3' ) THEN

         IF( LFIRST ) WRITE( IOUT, 95000 ) J1, J2, K1_3
         LFIRST = .FALSE.
         GO TO 400

      ELSEIF( LINEIN( 1 : 2 ) .EQ. 'S2' ) THEN
 
         GO TO 2000

      ELSE

         WRITE( IOUT, 92000 ) LINEIN( 1 : LEN_TRIM( LINEIN ) )

         GO TO 400

      END IF
 
2000  CONTINUE

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Finish solution section code
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

c..Find O3->O1D Rxn no.

      DO N = 1, NRXNS
         IF( IRR( N, 1 ) .EQ. O3 .AND. IRR( N, 4 ) .EQ. O1D  ) THEN
            KO3_O1D = N
            EXIT
         END IF
      END DO

c..Find NO2->NO2EX Rxn no. if NO2EX included in group
      IF( LNO2EX_CYCLE ) THEN
         DO N = 1, NRXNS
            IF( IRR( N, 1 ) .EQ. NO2 .AND. IRR( N, 4 ) .EQ. NO2EX  ) THEN
               KNO2_NO2EX = N
               EXIT
            END IF
         END DO
      END IF

      WRITE( IOUT, 96000 ) GC_SPC( NO  )( 1 : LEN_TRIM( GC_SPC( NO  ) ) )
      WRITE( IOUT, 96020 ) GC_SPC( NO2 )( 1 : LEN_TRIM( GC_SPC( NO2 ) ) )
      WRITE( IOUT, 96040 ) GC_SPC( NO2 )( 1 : LEN_TRIM( GC_SPC( NO2 ) ) )
      WRITE( IOUT, 96060 )
      WRITE( IOUT, 96080 ) GC_SPC( O3  )( 1 : LEN_TRIM( GC_SPC( O3 ) ) ),
     &                     GC_SPC( NO  )( 1 : LEN_TRIM( GC_SPC( NO ) ) )
      WRITE( IOUT, 96100 ) GC_SPC( O3P )( 1 : LEN_TRIM( GC_SPC( O3P ) ) )

      WRITE( RNUM, '(I3)' ) KO3_O1D
      RNUM = ADJUSTL( RNUM )
      WRITE( IOUT, 96120 ) GC_SPC( O1D )( 1 : LEN_TRIM( GC_SPC( O1D ) ) ),
     &                     RNUM( 1 : LEN_TRIM( RNUM ) ),
     &                     GC_SPC( O3  )( 1 : LEN_TRIM( GC_SPC( O3 ) ) )

      IF( LNO2EX_CYCLE ) THEN
         WRITE( RNUM, '(I3)' ) KNO2_NO2EX 
         RNUM = ADJUSTL( RNUM )
         WRITE( IOUT, 96130 ) GC_SPC( NO2EX )( 1 : LEN_TRIM( GC_SPC( NO2EX ) ) ),
     &                        RNUM( 1 : LEN_TRIM( RNUM ) ),
     &                        GC_SPC( NO2  )( 1 : LEN_TRIM( GC_SPC( NO2 ) ) )
         WRITE( IOUT, 96135 ) GC_SPC( NO2EX )( 1 : LEN_TRIM( GC_SPC( NO2EX ) ) ),
     &                        RNUM( 1 : LEN_TRIM( RNUM ) ),
     &                        GC_SPC( NO2  )( 1 : LEN_TRIM( GC_SPC( NO2 ) ) ),
     &                        GC_SPC( NO2  )( 1 : LEN_TRIM( GC_SPC( NO2 ) ) ),
     &                        GC_SPC( NO2EX )( 1 : LEN_TRIM( GC_SPC( NO2EX ) ) )
      END IF

      WRITE( IOUT, 96140 )

      CLOSE( IIN )

      CLOSE( IOUT )

      NOUTFLS = NOUTFLS + 1
      OUTFLNAM( NOUTFLS ) = 'hrg1.F'


      RETURN 

 9000 MSG = 'ERROR: Could not open ' // FNAME( 1 : LEN_TRIM( FNAME ) )

      CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT2 )
       
92000 FORMAT( A )
92020 FORMAT( / )

93000 FORMAT( 'C  PRECONDITIONS: For the ', A, ' family of mechanisms' )
93020 FORMAT( 'C  REVISION HISTORY: Created by EBI solver program, ', A )

93100 FORMAT( 'c  O1D Section' /
     &        'c    1) sum of the rate constants for all O1D loss reactions' /
     &        'c    2) get fractional yield of O3P from O1D loss' )

93200 FORMAT( 'c  NO2EX Section' /
     &        'c    1) sum of the rate constants for all NO2EX loss reactions' /
     &        'c    2) get fractional yield of NO2 from NO2EX loss' )

94000 FORMAT(
     & 'c  NO Section' /
     & 'c    R1_2 = production of NO from NO2 ( rates of form k[NO2][x] )' /
     & 'c           except NO2+NO3=NO+NO2 (it is treated as if it',
     &        ' were NO3=NO )' /
     & 'c    P1 =   remaining NO production terms' /
     & 'c    L1 =   loss of NO (except rxns producing NO2 - they',
     &       ' are in R2_1)' )

94020 FORMAT(
     & 'c  NO2 Section' /
     & 'c    R2_1 = production of NO2 from NO ( rates of form k[NO][x] )'/
     & 'c            a)  NO+O3=NO2 not included'/
     & 'c            b)  NO+NO3=2NO2 ( 1/2 of NO2 formation rate included )' /
     & 'c            c)  NO3+NO2=NO+NO2 is not included for NO2' /
     & 'c    P2 =  remaining NO2 production terms ' /
     & 'c            a)  NO+O3=NO2 not included' /
     & 'c            b)  NO+NO3=2NO2 (1/2 of NO2 formation rate included )' /
     & 'c    L2 = loss of NO2 (except rxns producing NO2 - they are in R1_2)' )

94040 FORMAT( 
     & 'c  O3 Section' /
     & 'c    P3 = production of O3 except O+O2=O3' /
     & 'c    L3 =   loss terms for O3 except NO+O3=NO2' )

94060 FORMAT(
     & 'c  O3P Section ' /
     & 'c    P12 = production of O3P except NO2+hv=O3P (J1)' /
     & 'c    L12 = loss terms' ) 


95000 FORMAT( 
     &'      RK1 = RKI( ', I3, ' ) * DTC            ! J1    (NO2+hv=NO+O3P)' /
     &'      RK2 = RKI( ', I3, ' ) * DTC            ! J2    (O3P+O2=O3)' /
     &'      RK3 = RKI( ', I3, ' ) * DTC            ! k1_3  (NO+O3=NO2)' )

96000 FORMAT( '      YCP( ', A, ' ) = MAX( 0.0, ( P1 + XX ) * L1_INV )' / )
96020 FORMAT( '      YCP( ', A, ' ) = MAX( 0.0, ( P2 - XX ) * L2_INV )' / )
96040 FORMAT( '      S1 = P12 + RK1 * YCP( ', A, ' )' / )
96060 FORMAT( '      S2 = T4 * S1' / )
96080 FORMAT( '      YCP( ', A, ' ) = ( P3 + S2 ) / ( L3 + RK3 * YCP( ',
     &               A, ' ) )' / )
96100 FORMAT( '      YCP( ', A, ' ) = S1 * L12_INV' / )
96120 FORMAT( '      YCP( ', A, ' ) = RKI( ', A, ' ) * YCP( ', A, 
     &               ' ) / O1D_S' / )
96130 FORMAT(  'C Steady State Solution ' /
     &         'C     YCP( ', A, ' ) = RKI( ', A, ' ) * YCP( ', A, 
     &               ' ) / EXN_S' / )

96135 FORMAT( 'C Time Dependent Solution ' /
     &               '      YCP( ', A, ' ) = RKI( ', A, ' )/EXN_S*(YCP( ', A,
     &               ' )  - YC0( ', A, ' )*EXP( -EXN_S*DTC ) ) ' / 
     &               '     &            + YC0( ', A, ' )*EXP( -EXN_S * DTC ) '
     &               / ) 

96140 FORMAT( '      RETURN' // '      END' // )



      END


