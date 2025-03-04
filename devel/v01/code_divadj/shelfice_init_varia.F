#include "SHELFICE_OPTIONS.h"

CBOP
      SUBROUTINE SHELFICE_INIT_VARIA( myThid )
C     *============================================================*
C     | SUBROUTINE SHELFICE_INIT_VARIA
C     | o Routine to initialize SHELFICE variables.
C     *============================================================*
C     | Initialize SHELFICE parameters and variables.
C     *============================================================*
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "SHELFICE.h"
#ifdef ALLOW_COST
# include "SHELFICE_COST.h"
#endif /* ALLOW_COST */

C     === Routine arguments ===
C     myThid -  Number of this instance of SHELFICE_INIT_VARIA
      INTEGER myThid
CEndOfInterface

#ifdef ALLOW_SHELFICE
C     === Local variables ===
C     i,j,bi,bj - Loop counters
      INTEGER i, j, k, bi, bj
CEOP

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
#ifdef ALLOW_AUTODIFF
C- Note: Follwing GMREDI_INIT_VARIA, 
C        to simplify dependency & avoid recomputations, when compiling
C        pkg/autodiff, we always call SHELFICE_INIT_VARIA to initialise control
C        variables (as done above) without condition on useSHELFICE.
C        Therefore, in this case, the "If useSHELFICE" is added back here:
      IF ( useSHELFICE ) THEN
#endif
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO j = 1-OLy, sNy+OLy
         DO i = 1-OLx, sNx+OLx
           shelficeForcingT      (i,j,bi,bj) = 0. _d 0
           shelficeForcingS      (i,j,bi,bj) = 0. _d 0
           shelficeHeatFlux      (i,j,bi,bj) = 0. _d 0
           shelficeFreshWaterFlux(i,j,bi,bj) = 0. _d 0
C Need to initialize SHIICFFreshWaterFlux to fix
C TAF warning message for top level
           SHIICFFreshWaterFlux(I,J,bi,bj)   = 0. _d 0
#ifndef ALLOW_shiTransCoeff_3d
           shiTransCoeffT        (i,j,bi,bj) = 0. _d 0
           shiTransCoeffS        (i,j,bi,bj) = 0. _d 0
#endif
           shelficeMass          (i,j,bi,bj) = 0. _d 0
           shiCDragFld           (i,j,bi,bj) = 0. _d 0
           shiDragQuadFld        (i,j,bi,bj) = 0. _d 0
          DO k = 1, NR
#ifdef ALLOW_shiTransCoeff_3d
             shiTransCoeffT        (i,j,k,bi,bj) = 0. _d 0
             shiTransCoeffS        (i,j,k,bi,bj) = 0. _d 0
#endif
            iceFrontHeatFlux(i,j,k,bi,bj)       = 0. _d 0
            iceFrontFreshWaterFlux(i,j,k,bi,bj) = 0. _d 0
            iceFrontForcingT(i,j,k,bi,bj)       = 0. _d 0
            iceFrontForcingS(i,j,k,bi,bj)       = 0. _d 0
          ENDDO
         ENDDO
        ENDDO
       ENDDO
      ENDDO
      IF ( .NOT. SHELFICEuseGammaFrict ) THEN
       IF ( SHELFICETransCoeffTFile .NE. ' ' ) THEN
#ifndef ALLOW_shiTransCoeff_3d
        CALL READ_FLD_XY_RL( SHELFICETransCoeffTFile, ' ',
     &                       shiTransCoeffT, 0, myThid )
        _EXCH_XY_RL( shiTransCoeffT, myThid )
#else
        CALL READ_FLD_XYZ_RL( SHELFICETransCoeffTFile, ' ',
     &                       shiTransCoeffT, 0, myThid )
        _EXCH_XYZ_RL( shiTransCoeffT, myThid )
#endif
        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
          DO j = 1-OLy, sNy+OLy
           DO i = 1-OLx, sNx+OLx
#ifndef ALLOW_shiTransCoeff_3d
            shiTransCoeffS(i,j,bi,bj) = SHELFICEsaltToHeatRatio *
     &                                  shiTransCoeffT(i,j,bi,bj)
#else
            DO k = 1, Nr
            shiTransCoeffS(i,j,k,bi,bj) = SHELFICEsaltToHeatRatio *
     &                                  shiTransCoeffT(i,j,k,bi,bj)
            ENDDO
#endif
           ENDDO
          ENDDO
         ENDDO
        ENDDO
       ELSE
C     set coefficients to constant values
        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
          DO j = 1-OLy, sNy+OLy
           DO i = 1-OLx, sNx+OLx
#ifndef ALLOW_shiTransCoeff_3d
            shiTransCoeffT(i,j,bi,bj) = SHELFICEheatTransCoeff
            shiTransCoeffS(i,j,bi,bj) = SHELFICEsaltTransCoeff
#else
            DO k = 1, Nr
            shiTransCoeffT(i,j,k,bi,bj) = SHELFICEheatTransCoeff
            shiTransCoeffS(i,j,k,bi,bj) = SHELFICEsaltTransCoeff
            ENDDO
#endif
           ENDDO
          ENDDO
         ENDDO
        ENDDO
       ENDIF
      ENDIF
C     Update the spatially varying version of the drag coefficient
C     shiCDragFld used in shelfice_thermodynamics
C     shiCDragQuadFld used in shelfice_u/v_drag_coeff
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO j = 1-OLy, sNy+OLy
         DO i = 1-OLx, sNx+OLx
          shiCDragFld(i,j,bi,bj) = shiCDrag
          shiDragQuadFld(i,j,bi,bj) = SHELFICEDragQuadratic
         ENDDO
        ENDDO
       ENDDO
      ENDDO

      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO j = 1-OLy, sNy+OLy
         DO i = 1-OLx, sNx+OLx
           shelficeMass(i,j,bi,bj) = shelficeMassInit(i,j,bi,bj)
         ENDDO
        ENDDO
       ENDDO
      ENDDO

      IF ( SHELFICEMassStepping .AND.
     &     ( nIter0.NE.0 .OR. startTime.NE.baseTime
     &                   .OR. pickupSuff.NE.' ') ) THEN
        CALL SHELFICE_READ_PICKUP( 1, nIter0, myThid )
c     ENDIF

c     IF ( SHELFICEMassStepping ) THEN
C     set/update "kTopC" to agree with changing ice-shelf mass
        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
          DO j = 1-OLy, sNy+OLy
           DO i = 1-OLx, sNx+OLx
             IF ( kSurfC(i,j,bi,bj).LE.Nr .AND.
     &            shelficeMass(i,j,bi,bj).GT.zeroRL ) THEN
               kTopC(i,j,bi,bj) = kSurfC(i,j,bi,bj)
             ELSE
               kTopC(i,j,bi,bj) = 0
             ENDIF
           ENDDO
          ENDDO
         ENDDO
        ENDDO
      ENDIF

#ifdef ALLOW_COST
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j = 1-OLy, sNy+OLy
          DO i = 1-OLx, sNx+OLx
           cMeanSHIforT (i,j,bi,bj) = 0. _d 0
           cMeanSHIforS (i,j,bi,bj) = 0. _d 0
          ENDDO
         ENDDO
       ENDDO
      ENDDO
c--
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
         objf_shelfice(bi,bj) = 0. _d 0
         objf_shifwflx(bi,bj) = 0. _d 0
         num_shifwflx(bi,bj)  = 0. _d 0
       ENDDO
      ENDDO
#endif /* ALLOW_COST */

#ifdef ALLOW_AUTODIFF
      ENDIF
#endif
#endif /* ALLOW_SHELFICE */

      RETURN
      END
