
!------------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in     !
!  continuous development by various groups and is based on information  !
!  from these groups: Federal Government employees, contractors working  !
!  within a United States Government contract, and non-Federal sources   !
!  including research institutions.  These groups give the Government    !
!  permission to use, prepare derivative works of, and distribute copies !
!  of their work in the CMAQ system to the public and to permit others   !
!  to do so.  The United States Environmental Protection Agency          !
!  therefore grants similar permission to use the CMAQ system software,  !
!  but users are requested to provide copies of derivative works or      !
!  products designed to operate in the CMAQ system to the United States  !
!  Government without restrictions as to use by others.  Software        !
!  that is used with the CMAQ system but distributed under the GNU       !
!  General Public License or the GNU Lesser General Public License is    !
!  subject to their copyright restrictions.                              !
!------------------------------------------------------------------------!

C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header$

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

         SUBROUTINE FIND_DEGRADED( JDATE, JTIME, LOGDEV, CALL_DEGRADE )

C**********************************************************************
C
C  Function:  Set Logic Flag in whether to call degradation routines
C
C  CALLED BY: HRDRIVER
C
C**********************************************************************
 
           USE DEGRADE_SETUP_TOX

           IMPLICIT NONE
 
C.....INCLUDES: NONE

C.....ARGUMENTS:

           INTEGER, INTENT( IN )  :: JDATE        ! current model date , coded YYYYDDD
           INTEGER, INTENT( IN )  :: JTIME        ! current model time , coded HHMMSS
           INTEGER, INTENT( IN )  :: LOGDEV       ! unit number for the log file
           LOGICAL, INTENT( OUT ) :: CALL_DEGRADE ! whether to call degradation routines

C.....LOCAL VARIABLES:

           CHARACTER( 144 )        :: XMSG                    ! Message text
           CHARACTER( 16  ), SAVE  :: PNAME = 'FIND_DEGRADED' ! Routine name

           CALL DEGRADE_DATA()

           CALL DEGRADE_MAP( JDATE, JTIME, LOGDEV )
           
           IF( N_REACT_FOUND .GT. 0 )THEN
               CALL_DEGRADE = .TRUE.
           ELSE
               CALL_DEGRADE = .FALSE.
           ENDIF
        
           RETURN
         
         END SUBROUTINE FIND_DEGRADED
