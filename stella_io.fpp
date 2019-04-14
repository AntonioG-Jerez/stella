# include "define.inc"

module stella_io

# ifdef NETCDF
  use netcdf, only: nf90_noerr
  use netcdf_utils, only: netcdf_error, kind_nf
# endif

  implicit none

  private

  public :: init_stella_io, finish_stella_io
  public :: write_time_nc
  public :: write_phi_nc
  public :: write_gvmus_nc
  public :: write_gzvs_nc
  public :: write_kspectra_nc
  public :: write_moments_nc

# ifdef NETCDF
  integer (kind_nf) :: ncid

  integer (kind_nf) :: naky_dim, nttot_dim, nmu_dim, nvtot_dim, nspec_dim
  integer (kind_nf) :: nakx_dim
  integer (kind_nf) :: time_dim, char10_dim, char200_dim, ri_dim, nlines_dim, nheat_dim
  integer (kind_nf) :: nalpha_dim

  integer, dimension (6) :: moment_dim
  integer, dimension (5) :: field_dim
  integer, dimension (4) :: vmus_dim
  integer, dimension (4) :: zvs_dim, kykxaz_dim
  integer, dimension (3) :: mode_dim, heat_dim, kykxz_dim
  integer, dimension (2) :: kx_dim, ky_dim, om_dim, flux_dim, nin_dim, fmode_dim
  integer, dimension (2) :: flux_surface_dim

  integer :: nakx_id
  integer :: naky_id, nttot_id, akx_id, aky_id, zed_id, nspec_id
  integer :: nmu_id, nvtot_id, mu_id, vpa_id
  integer :: time_id, phi2_id, theta0_id, nproc_id, nmesh_id
  integer :: phi_vs_t_id, phi2_vs_kxky_id
  integer :: density_id, upar_id, temperature_id
  integer :: gvmus_id, gzvs_id
  integer :: input_id
  integer :: charge_id, mass_id, dens_id, temp_id, tprim_id, fprim_id
  integer :: vnew_id, spec_type_id
  integer :: bmag_id, gradpar_id, gbdrift_id, gbdrift0_id
  integer :: cvdrift_id, cvdrift0_id, gds2_id, gds21_id, gds22_id
  integer :: kperp2_id
  integer :: grho_id, jacob_id, shat_id, drhodpsi_id, q_id
  integer :: beta_id
  integer :: code_id

# endif
  real :: zero
  
!  include 'netcdf.inc'
  
contains

  subroutine init_stella_io (write_phi_vs_t, write_kspectra, write_gvmus, &
!       write_gzvs, write_symmetry, write_moments)
       write_gzvs, write_moments)

    use mp, only: proc0
    use file_utils, only: run_name
# ifdef NETCDF
    use netcdf, only: nf90_clobber, nf90_create
    use netcdf_utils, only: get_netcdf_code_precision, netcdf_real
# endif

    implicit none

    logical, intent(in) :: write_phi_vs_t, write_kspectra, write_gvmus, write_gzvs
    logical, intent (in) :: write_moments!, write_symmetry
# ifdef NETCDF
    character (300) :: filename
    integer :: status

    zero = epsilon(0.0)

    if (netcdf_real == 0) netcdf_real = get_netcdf_code_precision()
    status = nf90_noerr

    filename = trim(trim(run_name)//'.out.nc')
    ! only proc0 opens the file:
    if (proc0) then
       status = nf90_create (trim(filename), nf90_clobber, ncid) 
       if (status /= nf90_noerr) call netcdf_error (status, file=filename)

       call define_dims
!       call define_vars (write_phi_vs_t, write_kspectra, write_gvmus, write_gzvs, write_symmetry, write_moments)
       call define_vars (write_phi_vs_t, write_kspectra, write_gvmus, write_gzvs, write_moments)
       call nc_grids
       call nc_species
       call nc_geo
    end if
# endif

  end subroutine init_stella_io

  subroutine define_dims

    use file_utils, only: num_input_lines
    use kt_grids, only: naky, nakx
    use zgrid, only: nzgrid
    use stella_geometry, only: nalpha
    use vpamu_grids, only: nvpa, nmu
    use species, only: nspec
# ifdef NETCDF
    use netcdf, only: nf90_unlimited
    use netcdf, only: nf90_def_dim
# endif

# ifdef NETCDF
    integer :: status

    ! Associate the grid variables, e.g. ky, kx, with their size, e.g. naky, nakx,
    ! and a variable which is later used to store these sizes in the NetCDF file, e.g. naky_dim, nakx_dim
    status = nf90_def_dim (ncid, 'ky', naky, naky_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='ky')
    status = nf90_def_dim (ncid, 'kx', nakx, nakx_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='kx')
    status = nf90_def_dim (ncid, 'theta0', nakx, nakx_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='theta0')
    status = nf90_def_dim (ncid, 'zed', 2*nzgrid+1, nttot_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='zed')
    status = nf90_def_dim (ncid, 'alpha', nalpha, nalpha_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='alpha')
    status = nf90_def_dim (ncid, 'vpa', nvpa, nvtot_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='vpa')
    status = nf90_def_dim (ncid, 'mu', nmu, nmu_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='mu')
    status = nf90_def_dim (ncid, 'species', nspec, nspec_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='species')
    status = nf90_def_dim (ncid, 't', nf90_unlimited, time_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='t')
    status = nf90_def_dim (ncid, 'char10', 10, char10_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='char10')
    status = nf90_def_dim (ncid, 'char200', 200, char200_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='char200')
    status = nf90_def_dim (ncid, 'nlines', num_input_lines, nlines_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='nlines')
    status = nf90_def_dim (ncid, 'ri', 2, ri_dim)
    if (status /= nf90_noerr) call netcdf_error (status, dim='ri')
# endif
  end subroutine define_dims

  subroutine nc_grids

    use zgrid, only: nzgrid, zed
    use kt_grids, only: naky, nakx
    use kt_grids, only: theta0, akx, aky
    use species, only: nspec
    use vpamu_grids, only: nvpa, nmu, vpa, mu
!    use nonlinear_terms, only: nonlin
# ifdef NETCDF
    use netcdf, only: nf90_put_var
    use constants, only: pi
    
    integer :: status
    real :: nmesh

    ! Store the size of the grid dimensions (as defined in def_dims), in the NetCDF file
    status = nf90_put_var (ncid, nttot_id, 2*nzgrid+1)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nttot_id)
    status = nf90_put_var (ncid, naky_id, naky)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, naky_id)
    status = nf90_put_var (ncid, nakx_id, nakx)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nakx_id)
    status = nf90_put_var (ncid, nspec_id, nspec)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nspec_id)
    status = nf90_put_var (ncid, nmu_id, nmu)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nmu_id)
    status = nf90_put_var (ncid, nvtot_id, nvpa)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nvtot_id)

    status = nf90_put_var (ncid, akx_id, akx)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, akx_id)
    status = nf90_put_var (ncid, aky_id, aky)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, aky_id)
    status = nf90_put_var (ncid, zed_id, zed)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, zed_id)
    status = nf90_put_var (ncid, theta0_id, theta0)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, theta0_id)
    status = nf90_put_var (ncid, mu_id, mu)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, mu_id)
    status = nf90_put_var (ncid, vpa_id, vpa)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, vpa_id)

!    if (nonlin) then
!       nmesh = (2*nzgrid+1)*(2*nvgrid+1)*nmu*nx*ny*nspec
!    else
       nmesh = (2*nzgrid+1)*nvpa*nmu*nakx*naky*nspec
!    end if

    status = nf90_put_var (ncid, nmesh_id, nmesh)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nmesh_id)

# endif
  end subroutine nc_grids

  subroutine finish_stella_io
    use mp, only: proc0
# ifdef NETCDF
    use netcdf, only: nf90_close
    use netcdf_utils, only: netcdf_error

    integer :: status

    if (proc0) then
       call save_input
       status = nf90_close (ncid)
       if (status /= nf90_noerr) call netcdf_error (status)
    end if
# endif
  end subroutine finish_stella_io

  subroutine save_input
    !<doc> Save the input file in the NetCDF file </doc>
# ifdef NETCDF    
    use file_utils, only: num_input_lines, get_input_unit
    use netcdf, only: nf90_put_var

    character(200) line
    integer, dimension (2) :: nin_start, nin_count

    integer :: status, n, unit

    nin_start(1) = 1
    nin_start(2) = 1

    nin_count(2) = 1

    call get_input_unit (unit)
    rewind (unit=unit)
    do n = 1, num_input_lines
       read (unit=unit, fmt="(a)") line
       nin_count(1) = len(trim(line))
!       status = nf_put_vara_text (ncid, input_id, nin_start, nin_count, line)
       status = nf90_put_var (ncid, input_id, line, start=nin_start, count=nin_count)
       if (status /= nf90_noerr) call netcdf_error (status, ncid, input_id)
       nin_start(2) = nin_start(2) + 1
    end do
# endif
  end subroutine save_input

  subroutine define_vars (write_phi_vs_t, write_kspectra, write_gvmus, &
!       write_gzvs, write_symmetry, write_moments)
       write_gzvs, write_moments)

    use mp, only: nproc
    use species, only: nspec
    use run_parameters, only: fphi, fapar, fbpar
# ifdef NETCDF
    use netcdf, only: nf90_char, nf90_int, nf90_global
    use netcdf, only: nf90_def_var, nf90_put_att, nf90_enddef, nf90_put_var
    use netcdf, only: nf90_inq_libvers
    use netcdf_utils, only: netcdf_real
# endif

    implicit none

    logical, intent(in) :: write_phi_vs_t, write_kspectra, write_gvmus, write_gzvs!, write_symmetry
    logical, intent (in) :: write_moments
# ifdef NETCDF
    character (5) :: ci
    character (20) :: datestamp, timestamp, timezone
    
    integer :: status

    flux_surface_dim(1) = nalpha_dim
    flux_surface_dim(2) = nttot_dim

    fmode_dim(1) = naky_dim
    fmode_dim(2) = nakx_dim

    mode_dim (1) = naky_dim
    mode_dim (2) = nakx_dim
    mode_dim (3) = time_dim

    kx_dim (1) = nakx_dim
    kx_dim (2) = time_dim
    
    ky_dim (1) = naky_dim
    ky_dim (2) = time_dim
    
    om_dim (1) = ri_dim
    om_dim (2) = time_dim

    nin_dim(1) = char200_dim
    nin_dim(2) = nlines_dim
    
    flux_dim (1) = nspec_dim
    flux_dim (2) = time_dim

    heat_dim (1) = nspec_dim
    heat_dim (2) = nheat_dim
    heat_dim (3) = time_dim

    field_dim (1) = ri_dim
    field_dim (2) = naky_dim
    field_dim (3) = nakx_dim
    field_dim (4) = nttot_dim
    field_dim (5) = time_dim

    moment_dim (1) = ri_dim
    moment_dim (2) = naky_dim
    moment_dim (3) = nakx_dim
    moment_dim (4) = nttot_dim
    moment_dim (5) = nspec_dim
    moment_dim (6) = time_dim

    vmus_dim (1) = nvtot_dim
    vmus_dim (2) = nmu_dim
    vmus_dim (3) = nspec_dim
    vmus_dim (4) = time_dim

    zvs_dim (1) = nttot_dim
    zvs_dim (2) = nvtot_dim
    zvs_dim (3) = nspec_dim
    zvs_dim (4) = time_dim
    
    kykxz_dim (1) = naky_dim
    kykxz_dim (2) = nakx_dim
    kykxz_dim (3) = nttot_dim

    kykxaz_dim (1) = naky_dim
    kykxaz_dim (2) = nakx_dim
    kykxaz_dim (3) = nalpha_dim
    kykxaz_dim (4) = nttot_dim

    ! Write some useful general information such as the website,
    ! date and time into the NetCDF file
    status = nf90_put_att (ncid, nf90_global, 'title', 'GS2 Simulation Data')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nf90_global, att='title')
    status = nf90_put_att (ncid, nf90_global, 'Conventions', &
         'http://gs2.sourceforge.net')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nf90_global, att='Conventions')

    datestamp(:) = ' '
    timestamp(:) = ' '
    timezone(:) = ' '
    call date_and_time (datestamp, timestamp, timezone)
    
    status = nf90_def_var (ncid, 'code_info', nf90_char, char10_dim, code_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='code_info')
    status = nf90_put_att (ncid, code_id, 'long_name', 'GS2')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att='long_name')

    ci = 'c1'
    status = nf90_put_att (ncid, code_id, trim(ci), 'Date: '//trim(datestamp))
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c2'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'Time: '//trim(timestamp)//' '//trim(timezone))
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c3'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'netCDF version '//trim(nf90_inq_libvers()))
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c4'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'Units are determined with respect to reference temperature (T_ref),')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c5'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'reference charge (q_ref), reference mass (mass_ref),')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c6'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'reference field (B_ref), and reference length (a_ref)')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c7'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'from which one may construct rho_ref and vt_ref/a,')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c8'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'which are the basic units of perpendicular length and time.')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c9'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'Macroscopic lengths are normalized to the minor radius.')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c10'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'The difference between rho (normalized minor radius) and rho (gyroradius)')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ci = 'c11'
    status = nf90_put_att (ncid, code_id, trim(ci), &
         'should be clear from the context in which they appear below.')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, code_id, att=ci)

    ! Write lots of input variables (e.g. nproc, nkx, nky)
    ! into the NetCDF file
    status = nf90_def_var (ncid, 'nproc', nf90_int, nproc_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='nproc')
    status = nf90_put_att (ncid, nproc_id, 'long_name', 'Number of processors')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nproc_id, att='long_name')

    status = nf90_def_var (ncid, 'nmesh', netcdf_real, nmesh_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='nmesh')
    status = nf90_put_att (ncid, nmesh_id, 'long_name', 'Number of meshpoints')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nmesh_id, att='long_name')

    status = nf90_def_var (ncid, 'nkx', nf90_int, nakx_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='nkx')
    status = nf90_def_var (ncid, 'nky', nf90_int, naky_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='nky')
    status = nf90_def_var (ncid, 'nzed_tot', nf90_int, nttot_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='nzed_tot')
    status = nf90_def_var (ncid, 'nspecies', nf90_int, nspec_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='nspecies')
    status = nf90_def_var (ncid, 'nmu', nf90_int, nmu_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='nmu')
    status = nf90_def_var (ncid, 'nvpa_tot', nf90_int, nvtot_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='nvpa_tot')

    status = nf90_def_var (ncid, 't', netcdf_real, time_dim, time_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='t')
    status = nf90_put_att (ncid, time_id, 'long_name', 'Time')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, time_id, att='long_name')
    status = nf90_put_att (ncid, time_id, 'units', 'L/vt')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, time_id, att='units')

    status = nf90_def_var (ncid, 'charge', nf90_int, nspec_dim, charge_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='charge')
    status = nf90_put_att (ncid, charge_id, 'long_name', 'Charge')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, charge_id, att='long_name')
    status = nf90_put_att (ncid, charge_id, 'units', 'q')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, charge_id, att='units')

    status = nf90_def_var (ncid, 'mass', netcdf_real, nspec_dim, mass_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='mass')
    status = nf90_put_att (ncid, mass_id, 'long_name', 'Atomic mass')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, mass_id, att='long_name')
    status = nf90_put_att (ncid, mass_id, 'units', 'm')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, mass_id, att='units')

    status = nf90_def_var (ncid, 'dens', netcdf_real, nspec_dim, dens_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='dens')
    status = nf90_put_att (ncid, dens_id, 'long_name', 'Density')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, dens_id, att='long_name')
    status = nf90_put_att (ncid, dens_id, 'units', 'n_e')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, dens_id, att='units')

    status = nf90_def_var (ncid, 'temp', netcdf_real, nspec_dim, temp_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='temp')
    status = nf90_put_att (ncid, temp_id, 'long_name', 'Temperature')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, temp_id, att='long_name')
    status = nf90_put_att (ncid, temp_id, 'units', 'T')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, temp_id, att='units')

    status = nf90_def_var (ncid, 'tprim', netcdf_real, nspec_dim, tprim_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='tprim')
    status = nf90_put_att (ncid, tprim_id, 'long_name', '-1/rho dT/drho')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, tprim_id, att='long_name')

    status = nf90_def_var (ncid, 'fprim', netcdf_real, nspec_dim, fprim_id) 
    if (status /= nf90_noerr) call netcdf_error (status, var='fprim')
    status = nf90_put_att (ncid, fprim_id, 'long_name', '-1/rho dn/drho')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, fprim_id, att='long_name')

    status = nf90_def_var (ncid, 'vnew', netcdf_real, nspec_dim, vnew_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='vnew')
    status = nf90_put_att (ncid, vnew_id, 'long_name', 'Collisionality')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, vnew_id, att='long_name')
    status = nf90_put_att (ncid, vnew_id, 'units', 'v_t/L')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, vnew_id, att='units')
    
    status = nf90_def_var (ncid, 'type_of_species', nf90_int, nspec_dim, spec_type_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='type_of_species')

    status = nf90_def_var (ncid, 'theta0', netcdf_real, fmode_dim, theta0_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='theta0')
    status = nf90_put_att (ncid, theta0_id, 'long_name', 'Theta_0')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, theta0_id, att='long_name')

    status = nf90_def_var (ncid, 'kx', netcdf_real, nakx_dim, akx_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='kx')
    status = nf90_put_att (ncid, akx_id, 'long_name', 'kx rho')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, akx_id, att='long_name')

    status = nf90_def_var (ncid, 'ky', netcdf_real, naky_dim, aky_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='ky')
    status = nf90_put_att (ncid, aky_id, 'long_name', 'ky rho')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, aky_id, att='long_name')

    status = nf90_def_var (ncid, 'mu', netcdf_real, nmu_dim, mu_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='mu')
    status = nf90_def_var (ncid, 'vpa', netcdf_real, nvtot_dim, vpa_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='vpa')

    status = nf90_def_var (ncid, 'zed', netcdf_real, nttot_dim, zed_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='zed')

    status = nf90_def_var (ncid, 'bmag', netcdf_real, flux_surface_dim, bmag_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='bmag')
    status = nf90_put_att (ncid, bmag_id, 'long_name', '|B|(alpha,zed)')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, bmag_id, att='long_name')
    status = nf90_put_att (ncid, bmag_id, 'units', 'B_0')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, bmag_id, att='units')

    status = nf90_def_var (ncid, 'gradpar', netcdf_real, flux_surface_dim, gradpar_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='gradpar')
    status = nf90_def_var (ncid, 'gbdrift', netcdf_real, flux_surface_dim, gbdrift_id) 
    if (status /= nf90_noerr) call netcdf_error (status, var='gbdrift')
    status = nf90_def_var (ncid, 'gbdrift0', netcdf_real, flux_surface_dim, gbdrift0_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='gbdrift0')
    status = nf90_def_var (ncid, 'cvdrift', netcdf_real, flux_surface_dim, cvdrift_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='cvdrift')
    status = nf90_def_var (ncid, 'cvdrift0', netcdf_real, flux_surface_dim, cvdrift0_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='cvdrift0')

    status = nf90_def_var (ncid, 'kperp2', netcdf_real, kykxaz_dim, kperp2_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='kperp2')
    status = nf90_def_var (ncid, 'gds2', netcdf_real, flux_surface_dim, gds2_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='gds2')
    status = nf90_def_var (ncid, 'gds21', netcdf_real, flux_surface_dim, gds21_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='gds21')
    status = nf90_def_var (ncid, 'gds22', netcdf_real, flux_surface_dim, gds22_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='gds22')
    status = nf90_def_var (ncid, 'grho', netcdf_real, nttot_dim, grho_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='grho')
    status = nf90_def_var (ncid, 'jacob', netcdf_real, nttot_dim, jacob_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='jacob')

    status = nf90_def_var (ncid, 'q', netcdf_real, q_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='q')
    status = nf90_put_att (ncid, q_id, 'long_name', 'local safety factor')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, q_id, att='long_name')
    status = nf90_def_var (ncid, 'beta', netcdf_real, beta_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='beta')
    status = nf90_put_att (ncid, beta_id, 'long_name', 'reference beta')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, beta_id, att='long_name')
    status = nf90_def_var (ncid, 'shat', netcdf_real, shat_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='shat')
    status = nf90_put_att (ncid, shat_id, 'long_name', '(rho/q) dq/drho')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, shat_id, att='long_name')
    
    status = nf90_def_var (ncid, 'drhodpsi', netcdf_real, drhodpsi_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='drhodpsi')
    status = nf90_put_att (ncid, drhodpsi_id, 'long_name', 'drho/dPsi')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, drhodpsi_id, att='long_name')
    
    if (fphi > zero) then
       status = nf90_def_var (ncid, 'phi2', netcdf_real, time_dim, phi2_id)
       if (status /= nf90_noerr) call netcdf_error (status, var='phi2')
       status = nf90_put_att (ncid, phi2_id, 'long_name', '|Potential**2|')
       if (status /= nf90_noerr) &
            call netcdf_error (status, ncid, phi2_id, att='long_name')
       status = nf90_put_att (ncid, phi2_id, 'units', '(T/q rho/L)**2')
       if (status /= nf90_noerr) &
            call netcdf_error (status, ncid, phi2_id, att='units')
       
!        status = nf90_def_var &
!             (ncid, 'phi2_by_mode', netcdf_real, mode_dim, phi2_by_mode_id)
!        if (status /= nf90_noerr) call netcdf_error (status, var='phi2_by_mode')
!        if (nakx > 1) then
!           status = nf90_def_var &
!                (ncid, 'phi2_by_kx', netcdf_real, kx_dim, phi2_by_kx_id)
!           if (status /= nf90_noerr) &
!                call netcdf_error (status, var='phi2_by_kx')
!        end if
       
!        if (naky > 1) then
!           status = nf90_def_var &
!                (ncid, 'phi2_by_ky', netcdf_real, ky_dim, phi2_by_ky_id)
!           if (status /= nf90_noerr) &
!                call netcdf_error (status, var='phi2_by_ky')
!        end if
       
       if (write_phi_vs_t) then
          status = nf90_def_var &
               (ncid, 'phi_vs_t', netcdf_real, field_dim, phi_vs_t_id)
          if (status /= nf90_noerr) call netcdf_error (status, var='phi_vs_t')
          status = nf90_put_att (ncid, phi_vs_t_id, 'long_name', 'Electrostatic Potential vs time')
          if (status /= nf90_noerr) call netcdf_error (status, ncid, phi_vs_t_id, att='long_name')
       end if
       if (write_kspectra) then
          status = nf90_def_var &
               (ncid, 'phi2_vs_kxky', netcdf_real, mode_dim, phi2_vs_kxky_id)
          if (status /= nf90_noerr) call netcdf_error (status, var='phi2_vs_kxky')
          status = nf90_put_att (ncid, phi2_vs_kxky_id, 'long_name', 'Electrostatic Potential vs (ky,kx,t)')
          if (status /= nf90_noerr) call netcdf_error (status, ncid, phi2_vs_kxky_id, att='long_name')
       end if
       if (write_moments) then
          status = nf90_def_var &
               (ncid, 'density', netcdf_real, moment_dim, density_id)
          if (status /= nf90_noerr) call netcdf_error (status, var='density')
          status = nf90_put_att (ncid, density_id, 'long_name', 'perturbed density vs (ky,kx,z,t)')
          if (status /= nf90_noerr) call netcdf_error (status, ncid, density_id, att='long_name')
          status = nf90_def_var &
               (ncid, 'upar', netcdf_real, moment_dim, upar_id)
          if (status /= nf90_noerr) call netcdf_error (status, var='upar')
          status = nf90_put_att (ncid, upar_id, 'long_name', 'perturbed parallel flow vs (ky,kx,z,t)')
          if (status /= nf90_noerr) call netcdf_error (status, ncid, upar_id, att='long_name')
          status = nf90_def_var &
               (ncid, 'temperature', netcdf_real, moment_dim, temperature_id)
          if (status /= nf90_noerr) call netcdf_error (status, var='temperature')
          status = nf90_put_att (ncid, temperature_id, 'long_name', 'perturbed temperature vs (ky,kx,z,t)')
          if (status /= nf90_noerr) call netcdf_error (status, ncid, temperature_id, att='long_name')
       end if
    end if

    if (write_gvmus) then
       status = nf90_def_var &
            (ncid, 'gvmus', netcdf_real, vmus_dim, gvmus_id)
       if (status /= nf90_noerr) call netcdf_error (status, var='gvmus')
       status = nf90_put_att (ncid, gvmus_id, 'long_name', &
            'guiding center distribution function averaged over real space')
       if (status /= nf90_noerr) call netcdf_error (status, ncid, gvmus_id, att='long_name')
    end if
    
    if (write_gzvs) then
       status = nf90_def_var &
            (ncid, 'gzvs', netcdf_real, zvs_dim, gzvs_id)
       if (status /= nf90_noerr) call netcdf_error (status, var='gzvs')
       status = nf90_put_att (ncid, gvmus_id, 'long_name', &
            'guiding center distribution function averaged over (kx,ky,mu)')
       if (status /= nf90_noerr) call netcdf_error (status, ncid, gzvs_id, att='long_name')
    end if

!    if (write_symmetry) then
!        status = nf90_def_var &
!             (ncid, 'pflx_zvpa', netcdf_real, zvs_dim, gzvs_id)
!        if (status /= nf90_noerr) call netcdf_error (status, var='gzvs')
!        status = nf90_put_att (ncid, gvmus_id, 'long_name', &
!             'guiding center distribution function averaged over (kx,ky,mu)')
!        if (status /= nf90_noerr) call netcdf_error (status, ncid, gzvs_id, att='long_name')
!    end if

    status = nf90_def_var (ncid, 'input_file', nf90_char, nin_dim, input_id)
    if (status /= nf90_noerr) call netcdf_error (status, var='input_file')
    status = nf90_put_att (ncid, input_id, 'long_name', 'Input file')
    if (status /= nf90_noerr) call netcdf_error (status, ncid, input_id, att='long_name')

    status = nf90_enddef (ncid)  ! out of definition mode
    if (status /= nf90_noerr) call netcdf_error (status)

    status = nf90_put_var (ncid, nproc_id, nproc)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, nproc_id)

# endif
  end subroutine define_vars

  subroutine write_time_nc (nout, time)

# ifdef NETCDF
    use netcdf, only: nf90_put_var
# endif

    implicit none

    integer, intent (in) :: nout
    real, intent (in) :: time

# ifdef NETCDF
    integer :: status

    status = nf90_put_var (ncid, time_id, time, start=(/ nout /))
    if (status /= nf90_noerr) call netcdf_error (status, ncid, time_id)
# endif

  end subroutine write_time_nc

  subroutine write_phi_nc (nout, phi)

    use convert, only: c2r
    use zgrid, only: nzgrid
    use kt_grids, only: nakx, naky
# ifdef NETCDF
    use netcdf, only: nf90_put_var
# endif

    implicit none

    integer, intent (in) :: nout
    complex, dimension (:,:,-nzgrid:), intent (in) :: phi

# ifdef NETCDF
    integer :: status
    integer, dimension (5) :: start, count
    real, dimension (:,:,:,:), allocatable :: phi_ri

    start = 1
    start(5) = nout
    count(1) = 2
    count(2) = naky
    count(3) = nakx
    count(4) = 2*nzgrid+1
    count(5) = 1

    allocate (phi_ri(2, naky, nakx, 2*nzgrid+1))
    call c2r (phi, phi_ri)
    status = nf90_put_var (ncid, phi_vs_t_id, phi_ri, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, phi_vs_t_id)
    deallocate (phi_ri)
# endif

  end subroutine write_phi_nc

  subroutine write_kspectra_nc (nout, phi2_vs_kxky)

    use kt_grids, only: nakx, naky
# ifdef NETCDF
    use netcdf, only: nf90_put_var
# endif

    implicit none

    integer, intent (in) :: nout
    real, dimension (:,:), intent (in) :: phi2_vs_kxky

# ifdef NETCDF
    integer :: status
    integer, dimension (3) :: start, count

    start = 1
    start(3) = nout
    count(1) = naky
    count(2) = nakx
    count(3) = 1

    status = nf90_put_var (ncid, phi2_vs_kxky_id, phi2_vs_kxky, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, phi2_vs_kxky_id)
# endif

  end subroutine write_kspectra_nc

  subroutine write_moments_nc (nout, density, upar, temperature)

    use convert, only: c2r
    use zgrid, only: nztot
    use kt_grids, only: nakx, naky
    use species, only: nspec
# ifdef NETCDF
    use netcdf, only: nf90_put_var
# endif

    implicit none

    integer, intent (in) :: nout
    complex, dimension (:,:,:,:), intent (in) :: density, upar, temperature

# ifdef NETCDF
    integer :: status
    integer, dimension (6) :: start, count
    real, dimension (:,:,:,:,:), allocatable :: mom_ri

    start = 1
    start(6) = nout
    count(1) = 2
    count(2) = naky
    count(3) = nakx
    count(4) = nztot
    count(5) = nspec
    count(6) = 1

    allocate (mom_ri(2, naky, nakx, nztot, nspec))

    call c2r (density, mom_ri)
    status = nf90_put_var (ncid, density_id, mom_ri, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, density_id)

    call c2r (upar, mom_ri)
    status = nf90_put_var (ncid, upar_id, mom_ri, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, upar_id)

    call c2r (temperature, mom_ri)
    status = nf90_put_var (ncid, temperature_id, mom_ri, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, temperature_id)

    deallocate (mom_ri)

# endif

  end subroutine write_moments_nc

  subroutine write_gvmus_nc (nout, g)

    use vpamu_grids, only: nvpa, nmu
    use species, only: nspec
# ifdef NETCDF
    use netcdf, only: nf90_put_var
# endif

    implicit none

    integer, intent (in) :: nout
    real, dimension (:,:,:), intent (in) :: g

# ifdef NETCDF
    integer :: status
    integer, dimension (4) :: start, count

    start(1) = 1
    start(2:3) = 1
    start(4) = nout
    count(1) = nvpa
    count(2) = nmu
    count(3) = nspec
    count(4) = 1

    status = nf90_put_var (ncid, gvmus_id, g, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, gvmus_id)
# endif

  end subroutine write_gvmus_nc

  subroutine write_gzvs_nc (nout, g)

    use zgrid, only: nzgrid
    use vpamu_grids, only: nvpa
    use species, only: nspec
# ifdef NETCDF
    use netcdf, only: nf90_put_var
# endif

    implicit none

    integer, intent (in) :: nout
    real, dimension (:,:,:), intent (in) :: g

# ifdef NETCDF
    integer :: status
    integer, dimension (4) :: start, count

    start(1:3) = 1
    start(4) = nout
    count(1) = 2*nzgrid+1
    count(2) = nvpa
    count(3) = nspec
    count(4) = 1

    status = nf90_put_var (ncid, gzvs_id, g, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, gzvs_id)
# endif

  end subroutine write_gzvs_nc

  subroutine nc_species

    use physics_parameters, only: beta
    use species, only: spec, nspec
# ifdef NETCDF
    use netcdf, only: nf90_put_var

    integer :: status
    integer :: is

    ! FLAG - ignoring cross-species collisions for now
    real, dimension (nspec) :: vnew
    do is = 1, nspec
       vnew(is) = spec(is)%vnew(is)
    end do

    status = nf90_put_var (ncid, charge_id, spec%z)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, charge_id)
    status = nf90_put_var (ncid, mass_id, spec%mass)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, mass_id)
    status = nf90_put_var (ncid, dens_id, spec%dens)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, dens_id)
    status = nf90_put_var (ncid, temp_id, spec%temp)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, temp_id)
    status = nf90_put_var (ncid, tprim_id, spec%tprim)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, tprim_id)
    status = nf90_put_var (ncid, fprim_id, spec%fprim)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, fprim_id)
    status = nf90_put_var (ncid, vnew_id, vnew)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, vnew_id)
    status = nf90_put_var (ncid, spec_type_id, spec%type)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, spec_type_id)

# endif
  end subroutine nc_species

  subroutine nc_geo

    use stella_geometry, only: bmag, gradpar, gbdrift, gbdrift0, &
         cvdrift, cvdrift0, gds2, gds21, gds22, grho, jacob, &
         drhodpsi
    use stella_geometry, only: geo_surf
    use stella_geometry, only: nalpha
    use zgrid, only: nzgrid
    use physics_parameters, only: beta
    use dist_fn_arrays, only: kperp2
    use kt_grids, only: naky, nakx
# ifdef NETCDF
    use netcdf, only: nf90_put_var

    implicit none

    integer :: status
    integer, dimension (2) :: start, count
    integer, dimension (4) :: start2, count2

    start = 1
    count(1) = nalpha
    count(2) = 2*nzgrid+1

    start2 = 1
    count2(1) = naky
    count2(2) = nakx
    count2(3) = nalpha
    count2(4) = 2*nzgrid+1

    status = nf90_put_var (ncid, bmag_id, bmag, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, bmag_id)
    status = nf90_put_var (ncid, gradpar_id, gradpar, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, gradpar_id)
    status = nf90_put_var (ncid, gbdrift_id, gbdrift, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, gbdrift_id)
    status = nf90_put_var (ncid, gbdrift0_id, gbdrift0, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, gbdrift0_id)
    status = nf90_put_var (ncid, cvdrift_id, cvdrift, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, cvdrift_id)
    status = nf90_put_var (ncid, cvdrift0_id, cvdrift0, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, cvdrift0_id)
    status = nf90_put_var (ncid, kperp2_id, kperp2, start=start2, count=count2)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, kperp2_id)
    status = nf90_put_var (ncid, gds2_id, gds2, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, gds2_id)
    status = nf90_put_var (ncid, gds21_id, gds21, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, gds21_id)
    status = nf90_put_var (ncid, gds22_id, gds22, start=start, count=count)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, gds22_id)
    status = nf90_put_var (ncid, grho_id, grho)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, grho_id)
    status = nf90_put_var (ncid, jacob_id, jacob)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, jacob_id)

    status = nf90_put_var (ncid, beta_id, beta)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, beta_id)
    status = nf90_put_var (ncid, q_id, geo_surf%qinp)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, q_id)
    status = nf90_put_var (ncid, shat_id, geo_surf%shat)
    if (status /= nf90_noerr) call netcdf_error (status, ncid, shat_id)
    status = nf90_put_var (ncid, drhodpsi_id, drhodpsi)   
    if (status /= nf90_noerr) call netcdf_error (status, ncid, drhodpsi_id)
# endif
  end subroutine nc_geo

end module stella_io
