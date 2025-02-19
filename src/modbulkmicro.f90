!> \file modbulkmicro.f90

!>
!!  Bulk microphysics.
!>
!! Calculates bulk microphysics using a two moment scheme.
!! \see   Seifert and Beheng (Atm. Res., 2001)
!! \see  Seifert and Beheng (Met Atm Phys, 2006)
!! \see  Stevens and Seifert (J. Meteorol. Soc. Japan, 2008)  (rain sedim, mur param)
!! \see  Seifert (J. Atm Sc., 2008) (rain evap)
!! \see  Khairoutdinov and Kogan (2000) (drizzle param : auto, accr, sedim, evap)
!!  \author Olivier Geoffroy, K.N.M.I.
!!  \author Margreet van Zanten, K.N.M.I.
!!  \author Stephan de Roode,TU Delft
!!  \par Revision list
!! \todo documentation
!  This file is part of DALES.
!
! DALES is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! DALES is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
!  Copyright 1993-2009 Delft University of Technology, Wageningen University, Utrecht University, KNMI
!


module modbulkmicro

!
!
!
!   Amount of liquid water is splitted into cloud water and precipitable
!   water (as such it is a two moment scheme). Cloud droplet number conc. is
!   fixed in place and time.
!
!   same rhof value used for some diagnostics calculation (in modbulkmicrostat, modtimestat)
!
!   Cond. sampled timeav averaged profiles are weighted with fraction of condition,
!   similarly as is done in sampling.f90
!
!   bulkmicro is called from *modmicrophysics*
!
!*********************************************************************
  use modmicrodata

  implicit none
  real :: gamma25
  real :: gamma3
  real :: gamma35
  contains

!> Initializes and allocates the arrays
  subroutine initbulkmicro
    use modglobal, only : ih,i1,jh,j1,k1
    implicit none


    allocate( Nr       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,Nrp      (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,qltot    (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,qr       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,qrp      (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,Nc       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,nuc      (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,thlpmcr  (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,qtpmcr   (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,sedc     (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,sed_qr   (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,sed_Nr   (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,Dvc      (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,xc       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,Dvr      (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,xr       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,mur      (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,lbdr     (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,au       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,phi      (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,tau      (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,ac       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,sc       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,br       (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,evap     (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,Nevap    (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,qr_spl   (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,Nr_spl   (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,wfall_qr (2-ih:i1+ih,2-jh:j1+jh,k1)  &
             ,wfall_Nr (2-ih:i1+ih,2-jh:j1+jh,k1))

    allocate(precep    (2-ih:i1+ih,2-jh:j1+jh,k1))
    allocate(qrmask    (2-ih:i1+ih,2-jh:j1+jh,k1)  &
            ,qcmask    (2-ih:i1+ih,2-jh:j1+jh,k1))

!
  gamma25=lacz_gamma(2.5)
  gamma3=2.
  gamma35=lacz_gamma(3.5)

  end subroutine initbulkmicro

!> Cleaning up after the run
  subroutine exitbulkmicro
  !*********************************************************************
  ! subroutine exitbulkmicro
  !*********************************************************************
    implicit none

    deallocate(Nr,Nrp,qltot,qr,qrp,Nc,nuc,thlpmcr,qtpmcr)

    deallocate(sedc,sed_qr,sed_Nr,Dvc,xc,Dvr,xr,mur,lbdr, &
               au,phi,tau,ac,sc,br,evap,Nevap,qr_spl,Nr_spl,wfall_qr,wfall_Nr)

    deallocate(precep)

  end subroutine exitbulkmicro

!> Calculates the microphysical source term.
  subroutine bulkmicro
    use modglobal, only : i1,j1,k1,rdt,rk3step,timee,rlv,cp
    use modfields, only : sv0,svm,svp,qtp,thlp,ql0,exnf,rhof
    use modbulkmicrostat, only : bulkmicrotend
    use modmpi,    only : myid
    implicit none
    integer :: i,j,k
    real :: qrtest,nrtest

    do j=2,j1
    do i=2,i1
    do k=1,k1
      !write (6,*) myid,i,j,k,sv0(i,j,k,inr),sv0(i,j,k,iqr)
      Nr  (i,j,k) = sv0(i,j,k,inr)
      qr  (i,j,k) = sv0(i,j,k,iqr)
    enddo
    enddo
    enddo
    Nrp    = 0.0
    qrp    = 0.0
    thlpmcr = 0.0
    qtpmcr  = 0.0
    Nc     = 0.0

    delt = rdt/ (4. - dble(rk3step))

    if ( timee .eq. 0. .and. rk3step .eq. 1 .and. myid .eq. 0) then
      write(*,*) 'l_lognormal',l_lognormal
      write(*,*) 'rhof(1)', rhof(1),' rhof(10)', rhof(10)
      write(*,*) 'l_mur_cst',l_mur_cst,' mur_cst',mur_cst
      write(*,*) 'nuc = param'
    endif

  !*********************************************************************
  ! remove neg. values of Nr and qr
  !*********************************************************************
    if (l_rain) then
       if (sum(qr, qr<0.) > 0.000001*sum(qr)) then
         write(*,*)'amount of neg. qr and Nr thrown away is too high  ',timee,' sec'
       end if
       if (sum(Nr, Nr<0.) > 0.000001*sum(Nr)) then
          write(*,*)'amount of neg. qr and Nr thrown away is too high  ',timee,' sec'
       end if

       do j=2,j1
       do i=2,i1 
       do k=1,k1
          if (Nr(i,j,k) < 0.)  then
            Nr(i,j,k) = 0.
          endif
          if (qr(i,j,k) < 0.)  then
            qr(i,j,k) = 0.
          endif
       enddo
       enddo
       enddo
    end if   ! l_rain

    do j=2,j1
    do i=2,i1
    do k=1,k1
       if (qr(i,j,k) .gt. qrmin.and.Nr(i,j,k).gt.0)  then
          qrmask (i,j,k) = .true.
       else
          qrmask (i,j,k) = .false. 
       endif
    enddo
    enddo
    enddo
   !write (6,*) 'second part done'

  !*********************************************************************
  ! calculate qltot and initialize cloud droplet number Nc
  !*********************************************************************

    do j=2,j1
    do i=2,i1
    do k=1,k1
       ql0    (i,j,k) = ql0 (i,j,k)
       qltot (i,j,k) = ql0  (i,j,k) + qr (i,j,k)
       if (ql0(i,j,k) > qcmin)  then
          Nc     (i,j,k) = Nc_0
          qcmask (i,j,k) = .true.
       else
          qcmask (i,j,k) = .false.
       end if
    enddo
    enddo
    enddo

  !*********************************************************************
  ! calculate Rain DSD integral properties & parameters xr, Dvr, lbdr, mur
  !*********************************************************************
    if (l_rain) then

      xr   (2:i1,2:j1,1:k1) = 0.
      Dvr  (2:i1,2:j1,1:k1) = 0.
      mur  (2:i1,2:j1,1:k1) = 30.
      lbdr (2:i1,2:j1,1:k1) = 0.

      if (l_sb ) then
        
        do j=2,j1
        do i=2,i1
        do k=1,k1
           if (qrmask(i,j,k)) then
             xr (i,j,k) = rhof(k)*qr(i,j,k)/(Nr(i,j,k)+eps0) ! JvdD Added eps0 to avoid floating point exception
             xr (i,j,k) = min(max(xr(i,j,k),xrmin),xrmax) ! to ensure xr is within borders
             Dvr(i,j,k) = (xr(i,j,k)/pirhow)**(1./3.)
           endif
        enddo
        enddo
        enddo


        if (l_mur_cst) then
        ! mur = cst
          do j=2,j1
          do i=2,i1
          do k=1,k1
            if (qrmask(i,j,k)) then
               mur(i,j,k) = mur_cst
               lbdr(i,j,k) = ((mur(i,j,k)+3.)*(mur(i,j,k)+2.)*(mur(i,j,k)+1.))**(1./3.)/Dvr(i,j,k)
            endif
          enddo
          enddo
          enddo
        else
        ! mur = f(Dv)
          do j=2,j1
          do i=2,i1
          do k=1,k1
            if (qrmask(i,j,k)) then
!
!             mur(2:i1,2:j1,1:k1) = 10. * (1+tanh(1200.*(Dvr(2:i1,2:j1,1:k1)-0.0014))) 
!             Stevens & Seifert (2008) param
!
              mur(i,j,k) = min(30.,- 1. + 0.008/ (qr(i,j,k)*rhof(k))**0.6)  ! G09b
              lbdr(i,j,k) = ((mur(i,j,k)+3.)*(mur(i,j,k)+2.)*(mur(i,j,k)+1.))**(1./3.)/Dvr(i,j,k)
            endif
          enddo
          enddo
          enddo

        endif

      else
         do j=2,j1
         do i=2,i1
         do k=1,k1
            if (qrmask(i,j,k).and.Nr(i,j,k).gt.0.) then
              xr  (i,j,k) = rhof(k)*qr(i,j,k)/(Nr(i,j,k)+eps0) ! JvdD Added eps0 to avoid floating point exception
              xr  (i,j,k) = min(xr(i,j,k),xrmaxkk) ! to ensure x_pw is within borders
              Dvr (i,j,k) = (xr(i,j,k)/pirhow)**(1./3.)
            endif
         enddo
         enddo
         enddo

      endif ! l_sb
    endif   ! l_rain
    !write (6,*) 'parameters calculated'

  !*********************************************************************
  ! call microphysical processes subroutines
  !*********************************************************************
    if (l_sedc)  call sedimentation_cloud

    if (l_rain) then
      call bulkmicrotend
      call autoconversion
      call bulkmicrotend
      call accretion
      call bulkmicrotend
      call evaporation
      call bulkmicrotend
      call sedimentation_rain
      call bulkmicrotend
    endif

    sv0(2:i1,2:j1,1:k1,inr)=Nr(2:i1,2:j1,1:k1)
    sv0(2:i1,2:j1,1:k1,iqr)=qr(2:i1,2:j1,1:k1)

  !*********************************************************************
  ! remove negative values and non physical low values
  !*********************************************************************
    do k=1,k1
    do j=2,j1
    do i=2,i1
      qrtest=svm(i,j,k,iqr)+(svp(i,j,k,iqr)+qrp(i,j,k))*delt
      nrtest=svm(i,j,k,inr)+(svp(i,j,k,inr)+nrp(i,j,k))*delt
      if ((qrtest < qrmin) .or. (nrtest < 0.) ) then ! correction, after Jerome's implementation in Gales
        qtp(i,j,k) = qtp(i,j,k) + qtpmcr(i,j,k) + svm(i,j,k,iqr)/delt + svp(i,j,k,iqr) + qrp(i,j,k)
        thlp(i,j,k) = thlp(i,j,k) +thlpmcr(i,j,k) - (rlv/(cp*exnf(k)))*(svm(i,j,k,iqr)/delt + svp(i,j,k,iqr) + qrp(i,j,k))
        svp(i,j,k,iqr) = - svm(i,j,k,iqr)/delt
        svp(i,j,k,inr) = - svm(i,j,k,inr)/delt
      else
      svp(i,j,k,iqr)=svp(i,j,k,iqr)+qrp(i,j,k)
      svp(i,j,k,inr) =svp(i,j,k,inr)+nrp(i,j,k)
      thlp(i,j,k)=thlp(i,j,k)+thlpmcr(i,j,k)
      qtp(i,j,k)=qtp(i,j,k)+qtpmcr(i,j,k)
      ! adjust negative qr tendencies at the end of the time-step
     end if
    enddo
    enddo
    enddo

  end subroutine bulkmicro
  !> Determine autoconversion rate and adjust qrp and Nrp accordingly
  !!
  !!   The autoconversion rate is formulated for f(x)=A*x**(nuc)*exp(-Bx),
  !!   decaying exponentially for droplet mass x.
  !!   It can easily be reformulated for f(x)=A*x**(nuc)*exp(-Bx**(mu)) and
  !!   by chosing mu=1/3 one would get a gamma distribution in drop diameter
  !!   -> faster rain formation. (Seifert)
  subroutine autoconversion
    use modglobal, only : i1,j1,k1,kmax,rlv,cp
    use modmpi,    only : myid
    use modfields, only : exnf,rhof,ql0
    implicit none
    integer i,j,k
    au = 0.

    if (l_sb ) then
    !
    ! SB autoconversion
    !
      tau(2:i1,2:j1,1:k1) = 0.
      phi(2:i1,2:j1,1:k1) = 0.
      nuc(2:i1,2:j1,1:k1) = 0.
      k_au = k_c/(20*x_s)

      do j=2,j1
      do i=2,i1
      do k=1,k1
         if (qcmask(i,j,k)) then 
            nuc    (i,j,k) = 1.58*(rhof(k)*ql0(i,j,k)*1000.) +0.72-1. !G09a
!           nuc    (i,j,k) = 0. !
            xc     (i,j,k) = rhof(k) * ql0(i,j,k) / Nc(i,j,k) ! No eps0 necessary
            au     (i,j,k) = k_au * (nuc(i,j,k)+2.) * (nuc(i,j,k)+4.) / (nuc(i,j,k)+1.)**2.    &
                    * (ql0(i,j,k) * xc(i,j,k))**2. * 1.225 ! *rho**2/rho/rho (= 1)
            tau    (i,j,k) = 1.0 - ql0(i,j,k) / qltot(i,j,k)
            phi    (i,j,k) = k_1 * tau(i,j,k)**k_2 * (1.0 -tau(i,j,k)**k_2)**3
            au     (i,j,k) = au(i,j,k) * (1.0 + phi(i,j,k)/(1.0 -tau(i,j,k))**2)

            qrp    (i,j,k) = qrp    (i,j,k) + au (i,j,k)
            Nrp    (i,j,k) = Nrp    (i,j,k) + au (i,j,k)/x_s
            qtpmcr (i,j,k) = qtpmcr (i,j,k) - au (i,j,k)
            thlpmcr(i,j,k) = thlpmcr(i,j,k) + (rlv/(cp*exnf(k)))*au(i,j,k)

         endif
      enddo
      enddo
      enddo

    else
    !
    ! KK00 autoconversion
    !
      do j=2,j1
      do i=2,i1
      do k=1,k1

         if (qcmask(i,j,k)) then
            au     (i,j,k) = 1350.0 * ql0(i,j,k)**(2.47) * (Nc(i,j,k)/1.0E6)**(-1.79)

            qrp    (i,j,k) = qrp    (i,j,k) + au(i,j,k)
            Nrp    (i,j,k) = Nrp    (i,j,k) + au(i,j,k) * rhof(k)/(pirhow*D0_kk**3.)
            qtpmcr (i,j,k) = qtpmcr (i,j,k) - au(i,j,k)
            thlpmcr(i,j,k) = thlpmcr(i,j,k) + (rlv/(cp*exnf(k)))*au(i,j,k)
         endif

      enddo
      enddo
      enddo

    end if !l_sb


    if (any(ql0(2:i1,2:j1,1:kmax)/delt - au(2:i1,2:j1,1:kmax) .lt. 0.)) then
      write(6,*)'au too large', count(ql0(2:i1,2:j1,1:kmax)/delt - au(2:i1,2:j1,1:kmax) .lt. 0.),myid
    end if

  end subroutine autoconversion

  subroutine accretion
  !*********************************************************************
  ! determine accr. + self coll. + br-up rate and adjust qrp and Nrp
  ! accordingly. Break-up : Seifert (2007)
  !*********************************************************************
    use modglobal, only : ih,i1,jh,j1,k1,kmax,rlv,cp
    use modfields, only : exnf,rhof,ql0
    use modmpi,    only : myid
    implicit none
    real , allocatable :: phi_br(:,:,:)
    integer :: i,j,k
    allocate (phi_br(2-ih:i1+ih,2-jh:j1+jh,k1))

    ac(2:i1,2:j1,1:k1)=0

    if (l_sb ) then
    !
    ! SB accretion
    !
     
     do j=2,j1
     do i=2,i1
     do k=1,k1
        if (qrmask(i,j,k) .and. qcmask(i,j,k)) then
           tau    (i,j,k) = 1.0 - ql0(i,j,k)/(qltot(i,j,k))
           phi    (i,j,k) = (tau(i,j,k)/(tau(i,j,k) + k_l))**4.
           ac     (i,j,k) = k_r *rhof(k)*ql0(i,j,k) * qr(i,j,k) * phi(i,j,k) * &
                            (1.225/rhof(k))**0.5
           qrp    (i,j,k) = qrp    (i,j,k) + ac(i,j,k)
           qtpmcr (i,j,k) = qtpmcr (i,j,k) - ac(i,j,k)
           thlpmcr(i,j,k) = thlpmcr(i,j,k) + (rlv/(cp*exnf(k)))*ac(i,j,k)
        endif
     enddo
     enddo
     enddo

    !
    ! SB self-collection & Break-up
    !
     sc(2:i1,2:j1,1:k1)=0
     br(2:i1,2:j1,1:k1)=0

     do j=2,j1
     do i=2,i1
     do k=1,k1
        if (qrmask(i,j,k)) then
           sc(i,j,k) = k_rr *rhof(k)* qr(i,j,k) * Nr(i,j,k)  &
                       * (1 + kappa_r/lbdr(i,j,k)*pirhow**(1./3.))**(-9.)* (1.225/rhof(k))**0.5
        endif
        if (Dvr(i,j,k) .gt. 0.30E-3 .and. qrmask(i,j,k)) then
           phi_br(i,j,k) = k_br * (Dvr(i,j,k)-D_eq)
           br(i,j,k) = (phi_br(i,j,k) + 1.) * sc(i,j,k)
        else
           br(i,j,k) = 0. ! (phi_br = -1)
        endif
     enddo
     enddo
     enddo

     Nrp(2:i1,2:j1,1:k1) = Nrp(2:i1,2:j1,1:k1) - sc(2:i1,2:j1,1:k1) + br(2:i1,2:j1,1:k1)

    else
    !
    ! KK00 accretion
    !
     do j=2,j1
     do i=2,i1
     do k=1,k1
        if (qrmask(i,j,k) .and. qcmask(i,j,k)) then
           ac     (i,j,k) = 67.0 * ( ql0(i,j,k) * qr(i,j,k) )**1.15
           qrp    (i,j,k) = qrp     (i,j,k) + ac(i,j,k)
           qtpmcr (i,j,k) = qtpmcr  (i,j,k) - ac(i,j,k)
           thlpmcr(i,j,k) = thlpmcr (i,j,k) + (rlv/(cp*exnf(k)))*ac(i,j,k)
        endif
     enddo
     enddo
     enddo

    end if !l_sb


   if (any(ql0(2:i1,2:j1,1:kmax)/delt - ac(2:i1,2:j1,1:kmax) .lt. 0.)) then
     write(6,*)'ac too large', count(ql0(2:i1,2:j1,1:kmax)/delt - ac(2:i1,2:j1,1:kmax) .lt. 0.),myid
   end if
 
   deallocate (phi_br)

  end subroutine accretion

!> Sedimentation of cloud water
!!
!!   The sedimentation of cloud droplets assumes a lognormal DSD in which the
!!   geometric std dev. is assumed to be fixed at 1.3.
!! sedimentation of cloud droplets
!! lognormal CDSD is assumed (1 free parameter : sig_g)
!! terminal velocity : Stokes velocity is assumed (v(D) ~ D^2)
!! flux is calc. anal.
  subroutine sedimentation_cloud
    use modglobal, only : i1,j1,k1,kmax,rlv,cp,dzf,pi
    use modfields, only : rhof,exnf,ql0
    implicit none
    integer :: i,j,k

!    real    :: ql0_spl(2-ih:i1+ih,2-jh:j1+jh,k1)       &! work variable
!              ,Nc_spl(2-ih:i1+ih,2-jh:j1+jh,k1)
!    real,save :: dt_spl,wfallmax
!
!    ql0_spl(2:i1,2:j1,1:k1) = ql0(2:i1,2:j1,1:k1)
!    Nc_spl(2:i1,2:j1,1:k1)  = Nc(2:i1,2:j1,1:k1)
!
!    wfallmax = 9.9
!    n_spl = ceiling(wfallmax*delt/(minval(dzf)))
!    dt_spl = delt/real(n_spl)
!
!    do jn = 1 , n_spl  ! time splitting loop

    sedc(2:i1,2:j1,1:k1) = 0.
    csed = c_St*(3./(4.*pi*rhow))**(2./3.)*exp(5.*log(sig_g)**2.)

    do j=2,j1
    do i=2,i1
    do k=1,k1
       if (qcmask(i,j,k)) then
          sedc(i,j,k) = csed*(Nc(i,j,k))**(-2./3.)*(ql0(i,j,k)*rhof(k))**(5./3.)
       endif
    enddo
    enddo
    enddo

    do k=1,kmax
    do j=2,j1
    do i=2,i1

      qtpmcr(i,j,k) = qtpmcr(i,j,k) + (sedc(i,j,k+1)-sedc(i,j,k))/(dzf(k)*rhof(k))
      thlpmcr(i,j,k) = thlpmcr(i,j,k) - (rlv/(cp*exnf(k))) &
                       *(sedc(i,j,k+1)-sedc(i,j,k))/(dzf(k)*rhof(k))
    enddo
    enddo
    enddo
  end subroutine sedimentation_cloud


!> Sedimentaion of rain
!! sedimentation of drizzle water
!! - gen. gamma distr is assumed. Terminal velocities param according to
!!   Stevens & Seifert. Flux are calc. anal.
!! - l_lognormal =T : lognormal DSD is assumed with D_g and N known and
!!   sig_g assumed. Flux are calc. numerically with help of a
!!   polynomial function
  subroutine sedimentation_rain
    use modglobal, only : ih,i1,jh,j1,k1,kmax,eps1,dzf
    use modfields, only : rhof
    use modmpi,    only : myid
    implicit none
    integer :: i,j,k,jn
    integer :: n_spl      !<  sedimentation time splitting loop
    real    :: pwcont
    real, allocatable :: wvar(:,:,:), xr_spl(:,:,:),Dvr_spl(:,:,:),&
                        mur_spl(:,:,:),lbdr_spl(:,:,:),Dgr(:,:,:)
    real,save :: dt_spl,wfallmax

    allocate( wvar(2-ih:i1+ih,2-jh:j1+jh,k1)       &!<  work variable
              ,xr_spl(2-ih:i1+ih,2-jh:j1+jh,k1)     &!<  for time splitting
              ,Dvr_spl(2-ih:i1+ih,2-jh:j1+jh,k1)    &!<     -
              ,mur_spl(2-ih:i1+ih,2-jh:j1+jh,k1)    &!<     -
              ,lbdr_spl(2-ih:i1+ih,2-jh:j1+jh,k1)   &!<     -
              ,Dgr(2-ih:i1+ih,2-jh:j1+jh,k1))        !<  lognormal geometric diameter

    qr_spl(2:i1,2:j1,1:k1) = qr(2:i1,2:j1,1:k1)
    Nr_spl(2:i1,2:j1,1:k1)  = Nr(2:i1,2:j1,1:k1)

    wfallmax = 9.9
    n_spl = ceiling(wfallmax*delt/(minval(dzf)))
    dt_spl = delt/real(n_spl)

    do jn = 1 , n_spl ! time splitting loop

      sed_qr(2:i1,2:j1,1:k1) = 0.
      sed_Nr(2:i1,2:j1,1:k1) = 0.

      if (l_sb ) then

       do j=2,j1
       do i=2,i1
       do k=1,k1
        if (qr_spl(i,j,k) > qrmin) then
          xr_spl (i,j,k) = rhof(k)*qr_spl(i,j,k)/(Nr_spl(i,j,k)+eps0) ! JvdD Added eps0 to avoid division by zero
          xr_spl (i,j,k) = min(max(xr_spl(i,j,k),xrmin),xrmax) ! to ensure xr is within borders
          Dvr_spl(i,j,k) = (xr_spl(i,j,k)/pirhow)**(1./3.)
        endif
       enddo
       enddo
       enddo


      if (l_lognormal) then
        do j = 2,j1
        do i = 2,i1
        do k = 1,kmax
          if (qr_spl(i,j,k) > qrmin) then
            Dgr(i,j,k) = (exp(4.5*(log(sig_gr))**2))**(-1./3.)*Dvr_spl(i,j,k) ! correction for width of DSD
            sed_qr(i,j,k) = 1.*sed_flux(Nr_spl(i,j,k),Dgr(i,j,k),log(sig_gr)**2,D_s,3)
            sed_Nr(i,j,k) = 1./pirhow*sed_flux(Nr_spl(i,j,k),Dgr(i,j,k) ,log(sig_gr)**2,D_s,0)
!        correction for the fact that pwcont .ne. qr_spl
!        actually in this way for every grid box a fall velocity is determined
            pwcont = liq_cont(Nr_spl(i,j,k),Dgr(i,j,k),log(sig_gr)**2,D_s,3)         ! note : kg m-3
            if (pwcont > eps1) then
              sed_qr(i,j,k) = (qr_spl(i,j,k)*rhof(k)/pwcont)*sed_qr(i,j,k)  ! or qr_spl*(sed_qr/pwcont) = qr_spl*fallvel.
            end if
          end if ! qr_spl threshold statement
        end do
        end do
        end do

      else
    !
    ! SB rain sedimentation
    !
        if (l_mur_cst) then
          mur_spl(2:i1,2:j1,1:k1) = mur_cst
        else
          do j=2,j1
          do i=2,i1
          do k=1,k1
            if (qr_spl(i,j,k) > qrmin) then
!             mur_spl(i,j,k) = 10. * (1+tanh(1200.*(Dvr_spl(i,j,k)-0.0014))) ! SS08
              mur_spl(i,j,k) = min(30.,- 1. + 0.008/ (qr_spl(i,j,k)*rhof(k))**0.6)  ! G09b
            endif
          enddo
          enddo
          enddo

        endif

        do j=2,j1
        do i=2,i1
        do k=1,k1
          if (qr_spl(i,j,k) > qrmin) then
              lbdr_spl(i,j,k) = ((mur_spl(i,j,k)+3.)*(mur_spl(i,j,k)+2.)* &
                                 (mur_spl(i,j,k)+1.))**(1./3.)/Dvr_spl(i,j,k)
              wfall_qr(i,j,k) = max(0.,(a_tvsb-b_tvsb*(1.+c_tvsb/lbdr_spl(i,j,k))**(-1.*(mur_spl(i,j,k)+4.))))
              wfall_Nr(i,j,k) = max(0.,(a_tvsb-b_tvsb*(1.+c_tvsb/lbdr_spl(i,j,k))**(-1.*(mur_spl(i,j,k)+1.))))
              sed_qr  (i,j,k) = wfall_qr(i,j,k)*qr_spl(i,j,k)*rhof(k)
              sed_Nr  (i,j,k) = wfall_Nr(i,j,k)*Nr_spl(i,j,k)
          endif
        enddo
        enddo
        enddo

      endif !l_lognormal

    else
    !
    ! KK00 rain sedimentation
    !
      do j=2,j1
      do i=2,i1
      do k=1,k1
        if (qr_spl(i,j,k) > qrmin) then
           xr_spl(i,j,k) = rhof(k)*qr_spl(i,j,k)/(Nr_spl(i,j,k)+eps0) !JvdD added eps0 to avoid division by zero
           xr_spl(i,j,k) = min(xr_spl(i,j,k),xrmaxkk) ! to ensure xr is within borders 
           Dvr_spl(i,j,k) = (xr_spl(i,j,k)/pirhow)**(1./3.)
           sed_qr(i,j,k) = max(0., 0.006*1.0E6*Dvr_spl(i,j,k)- 0.2) * qr_spl(i,j,k)*rhof(k) 
           sed_Nr(i,j,k) = max(0.,0.0035*1.0E6*Dvr_spl(i,j,k)- 0.1) * Nr_spl(i,j,k)
        endif
      enddo
      enddo
      enddo

    end if !l_sb
!
    do k = 1,kmax
      do j=2,j1
      do i=2,i1
        wvar(i,j,k) = qr_spl(i,j,k) + (sed_qr(i,j,k+1) - sed_qr(i,j,k))*dt_spl/(dzf(k)*rhof(k))
      enddo
      enddo
      if (any(wvar(2:i1,2:j1,k) .lt. 0.)) then
        write(6,*)'sed qr too large', count(wvar(2:i1,2:j1,k) .lt. 0.),myid, minval(wvar), minloc(wvar)
      end if
      do j=2,j1
      do i=2,i1
        Nr_spl(i,j,k) = Nr_spl(i,j,k) + &
                (sed_Nr(i,j,k+1) - sed_Nr(i,j,k))*dt_spl/dzf(k)
        qr_spl(i,j,k) = qr_spl(i,j,k) + &
                (sed_qr(i,j,k+1) - sed_qr(i,j,k))*dt_spl/(dzf(k)*rhof(k))
      enddo
      enddo
  
      if ( jn == 1. ) then
      do j=2,j1
      do i=2,i1
        precep(i,j,k) =  sed_qr(i,j,k)/rhof(k)   ! kg kg-1 m s-1
      enddo
      enddo
      endif

    end do  ! second k loop
!
    enddo ! time splitting loop

    Nrp(2:i1,2:j1,1:k1)= Nrp(2:i1,2:j1,1:k1) + (Nr_spl(2:i1,2:j1,1:k1) - Nr(2:i1,2:j1,1:k1))/delt
    qrp(2:i1,2:j1,1:k1)= qrp(2:i1,2:j1,1:k1) + (qr_spl(2:i1,2:j1,1:k1) - qr(2:i1,2:j1,1:k1))/delt

    deallocate (wvar, xr_spl,Dvr_spl,mur_spl,lbdr_spl,Dgr) 
  end subroutine sedimentation_rain

  !*********************************************************************
  !*********************************************************************

  subroutine evaporation
  !*********************************************************************
  ! Evaporation of prec. : Seifert (2008)
  ! Cond. (S>0.) neglected (all water is condensed on cloud droplets)
  !*********************************************************************

    use modglobal, only : ih,i1,jh,j1,k1,rv,rlv,cp,pi,mygamma251,mygamma21,lacz_gamma
    use modfields, only : exnf,qt0,svm,qvsl,tmp0,ql0,esl,qvsl,rhof,exnf
    implicit none
    integer :: i,j,k
    real, allocatable :: F(:,:,:),S(:,:,:),G(:,:,:)
    integer :: numel

    allocate( F(2-ih:i1+ih,2-jh:j1+jh,k1)     & ! ventilation factor
              ,S(2-ih:i1+ih,2-jh:j1+jh,k1)     & ! super or undersaturation
              ,G(2-ih:i1+ih,2-jh:j1+jh,k1)     & ! cond/evap rate of a drop
             )

    evap(2:i1,2:j1,1:k1) = 0.
    Nevap(2:i1,2:j1,1:k1) = 0.

    do j=2,j1
    do i=2,i1
    do k=1,k1
      if (qrmask(i,j,k)) then
        S   (i,j,k) = min(0.,(qt0(i,j,k)-ql0(i,j,k))/qvsl(i,j,k)- 1.)
        G   (i,j,k) = (Rv * tmp0(i,j,k)) / (Dv*esl(i,j,k)) + rlv/(Kt*tmp0(i,j,k))*(rlv/(Rv*tmp0(i,j,k)) -1.)
        G   (i,j,k) = 1./G(i,j,k)
      endif
    enddo
    enddo
    enddo

                
    if (l_sb ) then
       do j=2,j1
       do i=2,i1
       do k=1,k1
         if (qrmask(i,j,k)) then
           numel=nint(mur(i,j,k)*100.)
           F(i,j,k) = avf * mygamma21(numel)*Dvr(i,j,k) +  &
              bvf*Sc_num**(1./3.)*(a_tvsb/nu_a)**0.5*mygamma251(numel)*Dvr(i,j,k)**(3./2.) * &
              (1.-(1./2.)  *(b_tvsb/a_tvsb)    *(lbdr(i,j,k)/(   c_tvsb+lbdr(i,j,k)))**(mur(i,j,k)+2.5)  &
                 -(1./8.)  *(b_tvsb/a_tvsb)**2.*(lbdr(i,j,k)/(2.*c_tvsb+lbdr(i,j,k)))**(mur(i,j,k)+2.5)  &
                 -(1./16.) *(b_tvsb/a_tvsb)**3.*(lbdr(i,j,k)/(3.*c_tvsb+lbdr(i,j,k)))**(mur(i,j,k)+2.5) &
                 -(5./128.)*(b_tvsb/a_tvsb)**4.*(lbdr(i,j,k)/(4.*c_tvsb+lbdr(i,j,k)))**(mur(i,j,k)+2.5)  )
! *lbdr(i,j,k)**(mur(i,j,k)+1.)/f_gamma_1(i,j,k) factor moved to F
            evap(i,j,k) = 2*pi*Nr(i,j,k)*G(i,j,k)*F(i,j,k)*S(i,j,k)/rhof(k)
            Nevap(i,j,k) = c_Nevap*evap(i,j,k)*rhof(k)/xr(i,j,k)
         endif
       enddo
       enddo
       enddo

    else
       do j=2,j1
       do i=2,i1
       do k=1,k1
        if (qrmask(i,j,k)) then
           evap(i,j,k) = c_evapkk*2*pi*Dvr(i,j,k)*G(i,j,k)*S(i,j,k)*Nr(i,j,k)/rhof(k)
           Nevap(i,j,k) = evap(i,j,k)*rhof(k)/xr(i,j,k)
        endif
       enddo
       enddo
       enddo

    endif

    do j=2,j1
    do i=2,i1
    do k=1,k1  
       if (evap(i,j,k) < -svm(i,j,k,iqr)/delt .and. qrmask(i,j,k)) then
          Nevap(i,j,k) = - svm(i,j,k,inr)/delt
          evap (i,j,k) = - svm(i,j,k,iqr)/delt
       endif
    enddo
    enddo
    enddo

    do j=2,j1
    do i=2,i1
    do k=1,k1
    qrp(i,j,k) = qrp(i,j,k) + evap(i,j,k)
    Nrp(i,j,k) = Nrp(i,j,k) + Nevap(i,j,k)
    qtpmcr(i,j,k) = qtpmcr(i,j,k) -evap(i,j,k)
    thlpmcr(i,j,k) = thlpmcr(i,j,k) + (rlv/(cp*exnf(k)))*evap(i,j,k)
    enddo
    enddo
    enddo

    deallocate (F,S,G)


  end subroutine evaporation

  !*********************************************************************
  !*********************************************************************

  real function sed_flux(Nin,Din,sig2,Ddiv,nnn)

  !*********************************************************************
  ! Function to calculate numerically the analytical solution of the
  ! sedimentation flux between Dmin and Dmax based on
  ! Feingold et al 1986 eq 17 -20.
  ! fall velocity is determined by alfa* D^beta with alfa+ beta taken as
  ! specified in Rogers and Yau 1989 Note here we work in D and in SI
  ! (in Roger+Yau in cm units + radius)
  ! flux is multiplied outside sed_flux with 1/rho_air to get proper
  ! kg/kg m/s units
  !
  ! M.C. van Zanten    August 2005
  !*********************************************************************
    use modglobal, only : pi,rhow
    implicit none

    real, intent(in) :: Nin, Din, sig2, Ddiv
    integer, intent(in) :: nnn
    !para. def. lognormal DSD (sig2 = ln^2 sigma_g), D sep. droplets from drops
    !,power of of D in integral

    real, parameter ::   C = rhow*pi/6.     &
                        ,D_intmin = 1e-6    &
                        ,D_intmax = 4.3e-3

    real ::  alfa         & ! constant in fall velocity relation
            ,beta         & ! power in fall vel. rel.
            ,D_min        & ! min integration limit
            ,D_max        & ! max integration limit
            ,flux           ![kg m^-2 s^-1]

    integer :: k

    flux = 0.0

    if (Din < Ddiv) then
      alfa = 3.e5*100  ![1/ms]
      beta = 2
      D_min = D_intmin
      D_max = Ddiv
      flux = C*Nin*alfa*erfint(beta,Din,D_min,D_max,sig2,nnn)
    else
      do k = 1,3
        select case(k)
        case(1)        ! fall speed ~ D^2
          alfa = 3.e5*100 ![1/m 1/s]
          beta = 2
          D_min = Ddiv
          D_max = 133e-6
        case(2)        ! fall speed ~ D
          alfa = 4e3     ![1/s]
          beta = 1
          D_min = 133e-6
          D_max = 1.25e-3
        case default         ! fall speed ~ sqrt(D)
          alfa = 1.4e3 *0.1  ![m^.5 1/s]
          beta = .5
          D_min = 1.25e-3
          D_max = D_intmax
        end select
        flux = flux + C*Nin*alfa*erfint(beta,Din,D_min,D_max,sig2,nnn)
      end do
    end if
      sed_flux = flux
  end function sed_flux

  !*********************************************************************
  !*********************************************************************

  real function liq_cont(Nin,Din,sig2,Ddiv,nnn)

  !*********************************************************************
  ! Function to calculate numerically the analytical solution of the
  ! liq. water content between Dmin and Dmax based on
  ! Feingold et al 1986 eq 17 -20.
  !
  ! M.C. van Zanten    September 2005
  !*********************************************************************
    use modglobal, only : pi,rhow
    implicit none

    real, intent(in) :: Nin, Din, sig2, Ddiv
    integer, intent(in) :: nnn
    !para. def. lognormal DSD (sig2 = ln^2 sigma_g), D sep. droplets from drops
    !,power of of D in integral

    real, parameter :: beta = 0           &
                      ,C = pi/6.*rhow     &
                      ,D_intmin = 80e-6    &   ! value of start of rain D
                      ,D_intmax = 3e-3         !4.3e-3    !  value is now max value for sqrt fall speed rel.

    real ::  D_min        & ! min integration limit
            ,D_max          ! max integration limit

    if (Din < Ddiv) then
    D_min = D_intmin
    D_max = Ddiv
    else
    D_min = Ddiv
    D_max = D_intmax
    end if

    liq_cont = C*Nin*erfint(beta,Din,D_min,D_max,sig2,nnn)

  end function liq_cont

  !*********************************************************************
  !*********************************************************************

  real function erfint(beta, D, D_min, D_max, sig2,nnn )

  !*********************************************************************
  ! Function to calculate erf(x) approximated by a polynomial as
  ! specified in 7.1.27 in Abramowitz and Stegun
  ! NB phi(x) = 0.5(erf(0.707107*x)+1) but 1 disappears by substraction
  !
  !*********************************************************************
    implicit none
    real, intent(in) :: beta, D, D_min, D_max, sig2
    integer, intent(in) :: nnn

    real, parameter :: eps = 1e-10       &
                      ,a1 = 0.278393    & !a1 till a4 constants in polynomial fit to the error
                      ,a2 = 0.230389    & !function 7.1.27 in Abramowitz and Stegun
                      ,a3 = 0.000972    &
                      ,a4 = 0.078108
    real :: nn, ymin, ymax, erfymin, erfymax, D_inv

    D_inv = 1./(eps + D)
    nn = beta + nnn

    ymin = 0.707107*(log(D_min*D_inv) - nn*sig2)/(sqrt(sig2))
    ymax = 0.707107*(log(D_max*D_inv) - nn*sig2)/(sqrt(sig2))

    erfymin = 1.-1./((1.+a1*abs(ymin) + a2*abs(ymin)**2 + a3*abs(ymin)**3 +a4*abs(ymin)**4)**4)
    erfymax = 1.-1./((1.+a1*abs(ymax) + a2*abs(ymax)**2 + a3*abs(ymax)**3 +a4*abs(ymax)**4)**4)
    if (ymin < 0.) then
      erfymin = -1.*erfymin
    end if
    if (ymax < 0.) then
      erfymax = -1.*erfymax
    end if
    erfint = D**nn*exp(0.5*nn**2*sig2)*0.5*(erfymax-erfymin)
  !  if (erfint < 0.) write(*,*)'erfint neg'
    if (erfint < 0.) erfint = 0.
  end function erfint



end module modbulkmicro


