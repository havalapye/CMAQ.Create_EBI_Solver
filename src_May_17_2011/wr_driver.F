       SUBROUTINE WR_DRIVER

C**********************************************************************
C
C  FUNCTION: Create source code for the driver for the EBI solver
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
!         INCLUDE SUBST_IOPARMS   ! IOAPI parameters
!         INCLUDE SUBST_IODECL    ! IOAPI declarations
         INCLUDE SUBST_RXCMMN    ! Mechanism data
      
C..ARGUMENTS: None

C..PARAMETERS: None

C..EXTERNAL FUNCTIONS:
!      INTEGER   JUNIT          ! gets unit no.

C..SAVED LOCAL VARIABLES: None
 
C..SCRATCH LOCAL VARIABLES:
      CHARACTER(  16 )  ::    PNAME = 'WR_DRIVER'  ! Program name
      CHARACTER(  32)   ::    MNAME                ! Mech name to write
      CHARACTER(  32 )  ::    MOUT                 ! Mech name for putput
      CHARACTER( 256 )  ::    MSG                  ! Message text
      CHARACTER( 100 )  ::    LINEIN               ! Input line
      CHARACTER( 256 )  ::    FNAME                ! Name of file to open
      CHARACTER( 4 )    ::    COM_AE_TAG           ! Compatible Aerosol version

      INTEGER  :: EPOS         ! end pos of string
      INTEGER  :: IIN          ! Unit no. of input file
      INTEGER  :: IOUT         ! Unit no. of output file
      INTEGER  :: LOGDEV       ! Unit no. of logdev
      INTEGER  :: NMECH        ! No. of mechanism names to check
      INTEGER  :: N            ! Loop index

      LOGICAL  :: LOUT1 = .FALSE.  ! Flag for group 1 output processed
      LOGICAL  :: LOUT2 = .FALSE.  ! Flag for group 2 output processed
      LOGICAL  :: LOUT3 = .FALSE.  ! Flag for group 3 output processed
      LOGICAL  :: LOUT4 = .FALSE.  ! Flag for group 4 output processed
      LOGICAL  :: LOUT5 = .FALSE.  ! Flag for group 5 output processed

C**********************************************************************

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Open ouput file and driver template 
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      LOGDEV = INIT3()

      EPOS = LEN_TRIM( OUTPATH )

      FNAME = OUTPATH( 1 : EPOS ) // '/hrdriver.F' 

      IOUT = JUNIT()

      OPEN( UNIT = IOUT, FILE = FNAME, ERR = 9000 )


      IIN = JUNIT()

      EPOS = LEN_TRIM( TMPLPATH )

      FNAME = TMPLPATH( 1 : EPOS ) // '/hrdriver.F' 

      OPEN( UNIT = IIN, FILE = FNAME, ERR = 9000 )

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Start processing
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      IF( LWR_COPY ) CALL WR_COPYRT( IOUT )

      IF( LWR_CVS_HDR ) CALL WR_CVSHDR( IOUT )


  100 CONTINUE

      READ( IIN, 92000, END = 1000 ) LINEIN

      IF( LINEIN( 1 : 1 ) .NE. 'R' ) THEN

         WRITE( IOUT, 92000 ) LINEIN( 1 : LEN_TRIM( LINEIN ) )

      ELSE

         IF( LINEIN( 2 : 2 ) .EQ. '1' .AND. .NOT. LOUT1 ) THEN

            WRITE( IOUT, 93000 ) GC_TAG( 1 : LEN_TRIM( GC_TAG ) )

            LOUT1 = .TRUE. 

         ELSEIF( LINEIN( 2 : 2 ) .EQ. '2' .AND. .NOT. LOUT2 ) THEN

            WRITE( IOUT, 93020 ) CR_DATE( 1 : LEN_TRIM( CR_DATE ) )

            LOUT2 = .TRUE. 
            
         ELSEIF( LINEIN( 2 : 2 ) .EQ. '3' .AND. .NOT. LOUT3 ) THEN

            IF( L_ALL_MECHS )THEN

               MNAME = GC_TAG
               EPOS = LEN_TRIM( MNAME )
               MOUT = '                '
               MOUT( 1 : EPOS ) = MNAME( 1 : LEN_TRIM( MNAME ) )
               WRITE( IOUT, 93040 ) MOUT


               MNAME = GC_TAG( 1 : LEN_TRIM( GC_TAG ) ) // '_' //
     &                 AE_TAG( 1 : LEN_TRIM( AE_TAG ) )
               EPOS = LEN_TRIM( MNAME )
               MOUT = '                '
               MOUT( 1 : EPOS ) = MNAME( 1 : LEN_TRIM( MNAME ) )
               WRITE( IOUT, 93060 ) MOUT


               MNAME = GC_TAG( 1 : LEN_TRIM( GC_TAG ) ) // '_' //
     &              AQ_TAG( 1 : LEN_TRIM( AQ_TAG ) )
               EPOS = LEN_TRIM( MNAME )
               MOUT = '                '
               MOUT( 1 : EPOS ) = MNAME( 1 : LEN_TRIM( MNAME ) )
               WRITE( IOUT, 93060 ) MOUT

               COM_AE_TAG = 'AE3'
               IF( AQ_TAG(1:LEN_TRIM(AQ_TAG)) .EQ. COM_AE_TAG )THEN
                  MNAME = GC_TAG( 1 : LEN_TRIM( GC_TAG ) ) // '_' //
     &                    COM_AE_TAG // '_' //
     &                    AQ_TAG( 1 : LEN_TRIM( AQ_TAG ) )
                  EPOS = LEN_TRIM( MNAME )
                  MOUT = '                '
                  MOUT( 1 : EPOS ) = MNAME( 1 : LEN_TRIM( MNAME ) )
                  WRITE( IOUT, 93060 ) MOUT
               END IF
               
               MNAME = GC_TAG( 1 : LEN_TRIM( GC_TAG ) ) // '_' //
     &                 AE_TAG( 1 : LEN_TRIM( AE_TAG ) ) // '_' //
     &                 AQ_TAG( 1 : LEN_TRIM( AQ_TAG ) )
               EPOS = LEN_TRIM( MNAME )
               MOUT = '                '
               MOUT( 1 : EPOS ) = MNAME( 1 : LEN_TRIM( MNAME ) )
               WRITE( IOUT, 93060 ) MOUT

            ELSE

               WRITE( IOUT, 93080)MECHNAME(1:LEN_TRIM(MECHNAME))

            END IF

            LOUT3 = .TRUE.

         ELSEIF( LINEIN( 2 : 2 ) .EQ. '4' .AND. .NOT. LOUT4 ) THEN

            IF( L_ALL_MECHS )THEN
               WRITE( IOUT, 93100 ) GC_TAG( 1 : LEN_TRIM( GC_TAG ) )
            ELSE
               WRITE( IOUT, 93110 ) MECHNAME(1:LEN_TRIM(MECHNAME))
            END IF

            LOUT4 = .TRUE.

         ELSEIF( LINEIN( 2 : 2 ) .EQ. '5' .AND. .NOT. LOUT5 ) THEN

            IF( LDEGRADE_SUBS ) WRITE( IOUT, 93046 ) LINEIN( 3 : LEN_TRIM( LINEIN ) )

            LOUT5 = .FALSE.

         END IF

      END IF

      GO TO 100

 1000 CONTINUE

      CLOSE( IIN )

      CLOSE( IOUT )

      NOUTFLS = NOUTFLS + 1
      OUTFLNAM( NOUTFLS ) = 'hrdriver.F'

      RETURN 

 9000 MSG = 'ERROR: Could not open ' // FNAME( 1 : LEN_TRIM( FNAME ) )

      CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT2 )
       
92000 FORMAT( A )

93000 FORMAT( 'C  PRECONDITIONS: For the ', A, ' family of mechanisms' )
93020 FORMAT( 'C  REVISION HISTORY: Created by EBI solver program, ', A )
93030 FORMAT( 9X, 'IF( MECHNAME .NE. ''' , A, ''' ) THEN') 
93040 FORMAT( 9X, 'IF( MECHNAME .NE. ''' , A, ''' .AND.'  ) 
93046 FORMAT( A )
93060 FORMAT( 5X, '&       MECHNAME .NE. ''', A, ''' .AND.'  ) 
93080 FORMAT( 9X, 'IF( MECHNAME .NE. ''' , A, ''' ) THEN') 
93100 FORMAT( 5X, '&            // '' the ', A, ' chemical mechanisms''' )
93110 FORMAT( 5X, '&            // '' the ', A, ' chemical mechanism''' )

      END
