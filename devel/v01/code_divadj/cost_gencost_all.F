#include "ECCO_OPTIONS.h"

      subroutine cost_gencost_all( myiter, mytime, mythid )

c     ==================================================================
c     SUBROUTINE cost_gencost_all
c     ==================================================================
c
c     o Evaluate user defined penalty terms
c
c     ==================================================================
c     SUBROUTINE cost_gencost_all
c     ==================================================================

      implicit none

c     == global variables ==

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#ifdef ALLOW_ECCO
# include "ECCO_SIZE.h"
# include "ECCO.h"
#endif

c     == routine arguments ==

      integer mythid
      integer myiter
      _RL     mytime

#ifdef ALLOW_GENCOST_CONTRIBUTION
c     == local variables ==

      character*(max_len_mbuf) msgbuf
      integer nnzbar
      integer nnzobs
      integer k
      integer nrecloc, nrecperiodloc

c     == external functions ==

c     == end of interface ==

      do k = 1, NGENCOST

#ifdef READIN_MISFIT_FOR_COST_CALC
         if ( (using_gencost(k)).AND.
     &        ( ( gencost_flag(k).EQ.1 ).OR.
     &          ( gencost_flag(k).EQ.2 ) )
#else
         if ( (using_gencost(k)).AND.( gencost_flag(k).EQ.1 )
#endif
     &   .AND.( .NOT.gencost_is1d(k) ) ) then

#ifdef ALLOW_DEBUG
         IF ( debugLevel .GE. debLevD ) THEN
           write(msgbuf,'(a,x,i2.2)') 'gencost #', k
           call print_message( msgbuf, standardmessageunit,
     &        SQUEEZE_RIGHT , mythid)
         ENDIF
#endif

         if ( .NOT.gencost_is3d(k) ) then
           nnzbar = 1
           nnzobs = 1
         else
           nnzbar = nr
           nnzobs = nr
         endif

         nrecloc= gencost_nrec(k)
         nrecperiodloc= gencost_nrec(k)

         if(gencost_name(k)(1:8).eq.'shifwflx')then
         call cost_generic(
     &     nnzbar, gencost_barfile(k), gencost_dummy(k),
     &     nnzobs, gencost_datafile(k), gencost_errfile(k),
     &     mult_gencost(k), nrecloc, nrecperiodloc,
     &     gencost_startdate(1,k), gencost_period(k), 'i',
     &     gencost_spmin(k), gencost_spmax(k), gencost_spzero(k),
     &     gencost_preproc(1,k), gencost_preproc_c(1,k),
     &     gencost_preproc_i(1,k), gencost_preproc_r(1,k),
     &     gencost_posproc(1,k), gencost_posproc_c(1,k),
     &     gencost_posproc_i(1,k), gencost_posproc_r(1,k),
     &     gencost_outputlevel(k), gencost_name(k),
     &     objf_gencost(1,1,k), num_gencost(1,1,k),
     &     myiter, mytime, mythid )
          else
         call cost_generic(
     &     nnzbar, gencost_barfile(k), gencost_dummy(k),
     &     nnzobs, gencost_datafile(k), gencost_errfile(k),
     &     mult_gencost(k), nrecloc, nrecperiodloc,
     &     gencost_startdate(1,k), gencost_period(k), 'c',
     &     gencost_spmin(k), gencost_spmax(k), gencost_spzero(k),
     &     gencost_preproc(1,k), gencost_preproc_c(1,k),
     &     gencost_preproc_i(1,k), gencost_preproc_r(1,k),
     &     gencost_posproc(1,k), gencost_posproc_c(1,k),
     &     gencost_posproc_i(1,k), gencost_posproc_r(1,k),
     &     gencost_outputlevel(k), gencost_name(k),
     &     objf_gencost(1,1,k), num_gencost(1,1,k),
     &     myiter, mytime, mythid )
          endif

         endif ! if ( (using_gencost(k)).AND.( gencost_flag(k).EQ.1 ) ) then

      end do

      call cost_gencost_glbmean( mythid )
C     call cost_gencost_boxmean( mythid )
      call cost_gencost_bpv4( mythid )
      call cost_gencost_moc( mythid )
      IF (using_cost_transp) call cost_gencost_transp( mythid )
      IF (using_cost_altim) call cost_gencost_sshv4( mythid )
      IF (using_cost_sst) call cost_gencost_sstv4( mythid )
#ifndef READIN_MISFIT_FOR_COST_CALC
      IF (using_cost_seaice) call cost_gencost_seaicev4( mythid )
#endif

#endif /* ALLOW_GENCOST_CONTRIBUTION */

      return
      end
