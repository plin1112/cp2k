!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright (C) 2000 - 2018  CP2K developers group                                               !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief Utility routines for qs_scf
! **************************************************************************************************
MODULE qs_scf_post_scf
   USE basis_set_output,                ONLY: print_basis_set_file
   USE cp_control_types,                ONLY: dft_control_type
   USE input_section_types,             ONLY: section_vals_get,&
                                              section_vals_get_subs_vals,&
                                              section_vals_type
   USE lri_optimize_ri_basis,           ONLY: optimize_lri_basis
   USE qs_band_structure,               ONLY: calculate_band_structure
   USE qs_environment_types,            ONLY: get_qs_env,&
                                              qs_environment_type
   USE qs_scf_post_dftb,                ONLY: scf_post_calculation_dftb
   USE qs_scf_post_gpw,                 ONLY: scf_post_calculation_gpw
   USE qs_scf_post_se,                  ONLY: scf_post_calculation_se
   USE qs_scf_types,                    ONLY: qs_scf_env_type
#include "./base/base_uses.f90"

   IMPLICIT NONE

   PRIVATE

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'qs_scf_post_scf'

   PUBLIC:: qs_scf_compute_properties

CONTAINS

! **************************************************************************************************
!> \brief computes properties for a given hamilonian using the current wfn
!> \param qs_env ...
!> \param dft_section ...
!> \param wf_type ...
! **************************************************************************************************
   SUBROUTINE qs_scf_compute_properties(qs_env, dft_section, wf_type)
      TYPE(qs_environment_type), POINTER                 :: qs_env
      TYPE(section_vals_type), POINTER                   :: dft_section
      CHARACTER(6), OPTIONAL                             :: wf_type

      CHARACTER(len=*), PARAMETER :: routineN = 'qs_scf_compute_properties', &
         routineP = moduleN//':'//routineN

      LOGICAL                                            :: explicit
      TYPE(dft_control_type), POINTER                    :: dft_control
      TYPE(qs_scf_env_type), POINTER                     :: scf_env
      TYPE(section_vals_type), POINTER                   :: print_section

      CALL get_qs_env(qs_env, scf_env=scf_env, dft_control=dft_control)

      IF (dft_control%qs_control%semi_empirical) THEN
         CALL scf_post_calculation_se(qs_env)
      ELSEIF (dft_control%qs_control%dftb) THEN
         CALL scf_post_calculation_dftb(dft_section, scf_env, qs_env)
      ELSEIF (dft_control%qs_control%do_kg) THEN
         CPWARN("No properties from PRINT section available for KG methods")
      ELSEIF (dft_control%qs_control%ofgpw) THEN
         CPWARN("No properties from PRINT section available for OFGPW methods")
      ELSEIF (dft_control%qs_control%lri_optbas .AND. dft_control%qs_control%gpw) THEN
         CALL optimize_lri_basis(qs_env)
      ELSE
         IF (PRESENT(wf_type)) THEN
            CALL scf_post_calculation_gpw(dft_section, scf_env, qs_env, wf_type=wf_type)
         ELSE
            CALL scf_post_calculation_gpw(dft_section, scf_env, qs_env)
         ENDIF
      END IF

      CALL calculate_band_structure(qs_env)

      print_section => section_vals_get_subs_vals(dft_section, "PRINT%BASIS_SET_FILE")
      CALL section_vals_get(print_section, explicit=explicit)
      IF (explicit) THEN
         CALL print_basis_set_file(qs_env, print_section)
      END IF

   END SUBROUTINE qs_scf_compute_properties

END MODULE qs_scf_post_scf
