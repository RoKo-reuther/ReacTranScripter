SUBROUTINE tran1d (N, C, BCup, BCdown, VALup, VALdown, ablup, abldown, &
                 & Dint, vint, AFDW, VF, VFint, A, Aint, dx, dxaux, dC, JF)

    ! Calculates flux (diffusive + advective) in a 1D finite differences grid.
    ! This is basically a fortran-copy of the R-function 'ReacTran::tran.1D'.
    
    IMPLICIT NONE

    !----- INPUT PARAMETERS -----

    ! Number of grid layers
    INTEGER                  :: N

    ! Concentration
    REAL(kind = 8)           :: C(N)

    ! Type of upper and lower boundary condition
    INTEGER                  :: BCup, BCdown
    INTEGER, PARAMETER       :: Flux     = 1
    INTEGER, PARAMETER       :: Value    = 2
    INTEGER, PARAMETER       :: ZeroGrad = 3
    INTEGER, PARAMETER       :: Convect  = 4

    ! Values at upper and lower boundary (flux or concentration)
    REAL(kind = 8)           :: VALup, VALdown

    ! Convective transfer coefficients
    REAL(kind = 8)           :: ablup, abldown

    ! Diffusion coefficient at interfaces
    REAL(kind = 8)           :: Dint(N+1) 

    ! Velocity at interfaces
    REAL(kind = 8)           :: vint(N+1)  

    ! Weight used in finite difference scheme for advection
    ! 1=backward; 0=forward; 0.5=centred
    REAL(kind = 8)           :: AFDW(N+1)

    ! Volume fraction at interfaces and midcell
    REAL(kind = 8)           :: VFint(N+1), VF(N)

    ! Interface area at interfaces and midcell
    REAL(kind = 8)           :: Aint(N+1), A(N)

    ! Distances between interfaces; distance between centers and boundaries
    REAL(kind = 8)           :: dx(N), dxaux(N+1)

    !----- VARIABLES TO CHANGE ------

    ! Change of concentration
    REAL(kind = 8)           :: dC(N)

    ! Flux
    REAL(kind = 8)           :: JF(N+1)

    !----- LOCAL VARIABLES -----

    REAL(kind = 8)           :: nom, denom
    REAL(kind = 8)           :: all_concs(N+2)
    REAL(kind = 8)           :: Cup, Cdown
    INTEGER                  :: i


    !--------------------------------------------------------------------------


    IF (BCup == Flux .or. BCup == ZeroGrad) THEN
        Cup = C(1)
    ELSEIF (BCup == Value .or. BCup == Convect) THEN
        Cup = VALup
    ENDIF

    IF (BCdown == Flux .or. BCdown == ZeroGrad) THEN
        Cdown = C(N)
    ELSEIF (BCdown == Value .or. BCdown == Convect) THEN
        Cdown = VALdown
    ENDIF

    IF (BCup == Convect) THEN
        IF (vint(1) >= 0) THEN
            nom = ablup * Cup + VFint(1) * Dint(1)/dxaux(1) + &
                & (1 - AFDW(1)) * vint(1) * C(1)
            denom = ablup + VFint(1) * (Dint(1) / dxaux(1) + AFDW(1) * vint(1))
        ELSE
            nom = ablup * Cup + VFint(1) * (Dint(1) / dxaux(1) + AFDW(1) * vint(1) * C(1))
            denom = ablup + VFint(1) * (Dint(1) / dxaux(1) + (1 - AFDW(1)) * vint(1))
        ENDIF
        Cup = nom / denom
    ENDIF
    
    IF (BCdown == Convect) THEN
        IF (vint(N+1) >= 0) THEN
            nom = abldown * Cdown + VFint(N+1) * (Dint(N+1) / dxaux(N+1) + &
                & (1 - AFDW(N+1)) * vint(N+1)) * C(N)
            denom = abldown + VFint(N+1) * Dint(N+1) / dxaux(N+1) + AFDW(N+1) * vint(N+1)
        ELSE
            nom = abldown * Cdown + VFint(N+1) * (Dint(N+1) / dxaux(N+1) + AFDW(N+1) * vint(N+1)) * C(N)
            denom = abldown + VFint(N+1) * (Dint(N+1) / dxaux(N+1) + (1 - AFDW(N+1)) * vint(N+1))
        ENDIF
        Cdown = nom / denom
    ENDIF
    
    all_concs(1) = Cup
    all_concs(2:(N+1)) = C
    all_concs(N+2) = Cdown
    
    DO i = 1, N+1
        ! Diffusive Flux
        JF(i) = -VFint(i) * Dint(i) * ( all_concs(i+1) - all_concs(i) ) / dxaux(i)
        ! Advective Flux
        IF (vint(i) > 0) THEN
            JF(i) = JF(i) + VFint(i) * vint(i) * ( AFDW(i) * all_concs(i) + &
                  & ( 1 - AFDW(i) ) * all_concs(i+1) )
        ELSEIF (vint(i) < 0) THEN
            JF(i) = JF(i) + VFint(i) * vint(i) * ( AFDW(i) * all_concs(i+1) + &
                  & ( 1 - AFDW(i) ) * all_concs(i) )
        ENDIF
    END DO
    
    IF (BCup == Flux) THEN
        JF(1) = VALup
    ENDIF
    IF (BCdown == Flux) THEN
        JF(N+1) = VALdown
    ENDIF
    
    DO i = 1, N 
        dC(i) = - ( Aint(i+1) * JF(i+1) - Aint(i) * JF(i) ) / A(i) / VF(i) / dx(i)
    END DO
    
    
END SUBROUTINE tran1d