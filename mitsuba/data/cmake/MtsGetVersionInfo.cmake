# ============================================================================
#   HDRITools - High Dynamic Range Image Tools
#   Copyright 2008-2011 Program of Computer Graphics, Cornell University
#
#   Distributed under the OSI-approved MIT License (the "License");
#   see accompanying file LICENSE for details.
#
#   This software is distributed WITHOUT ANY WARRANTY; without even the
#   implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the License for more information.
#  ---------------------------------------------------------------------------
#  Primary author:
#      Edgar Velazquez-Armendariz <cs#cornell#edu - eva5>
# ============================================================================

# - Sets up the version info variables
# This module provides a function intended to be called ONLY from the root dir:
#  MTS_GET_VERSION_INFO()
# This function will read the "include/mitsuba/core/version.h" file and execute
# "hg", setting the following variables:
#  MTS_VERSION       - Full version string: <major>.<minor>.<patch>
#  MTS_VERSION_MAJOR
#  MTS_VERSION_MINOR
#  MTS_VERSION_PATCH
#  MTS_VERSION_BUILD - Simple build number based on MTS_DATE,
#                      encoded as YYYYMMDD
#  MTS_HAS_VALID_REV - Flag to indicate whether MTS_REV_ID is set
#  MTS_REV_ID        - First 12 digits of the mercurial revision ID
#  MTS_DATE          - Represents the code date as YYYY.MM.DD
#  MTS_MACLS_VERSION - A version for Mac Launch Services from the version and
#                      code date, in the format nnnnn.nn.nn[hgXXXXXXXXXXXX]

function(MTS_GET_VERSION_INFO)

  # Simple, internal macro for zero padding values. Assumes that the number of
  # digits is enough. Note that this method overwrites the variable!
  macro(ZERO_PAD NUMBER_VAR NUM_DIGITS)
    set(_val ${${NUMBER_VAR}})
    set(${NUMBER_VAR} "")
    foreach(dummy_var RANGE 1 ${NUM_DIGITS})
      math(EXPR _digit "${_val} % 10")
      set(${NUMBER_VAR} "${_digit}${${NUMBER_VAR}}")
      math(EXPR _val "${_val} / 10")
    endforeach()
    unset(_val)
    unset(_digit)
  endmacro()


  # Uses hg to get the version string and the date of such revision
  # Based on info from:
  #  http://mercurial.selenic.com/wiki/VersioningWithMake (January 2011)

  # Try to directly get the information assuming the source is within a repo
  find_program(HG_CMD hg DOC "Mercurial command line executable")
  mark_as_advanced(HG_CMD)
  if (HG_CMD)
    execute_process(
      COMMAND "${HG_CMD}" -R "${PROJECT_SOURCE_DIR}"
                          parents --template "{node|short},{date|shortdate}"
      OUTPUT_VARIABLE HG_INFO
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (HG_INFO)
      # Extract the revision ID and the date
      string(REGEX REPLACE "(.+),.+" "\\1" MTS_REV_ID "${HG_INFO}")
      string(REGEX REPLACE ".+,(.+)-(.+)-(.+)" "\\1.\\2.\\3"
        MTS_DATE "${HG_INFO}")
      set(MTS_REV_ID ${MTS_REV_ID} PARENT_SCOPE)
      set(MTS_DATE   ${MTS_DATE}   PARENT_SCOPE)
    endif()
  endif()
  
  # If that failed, try grabbing the id from .hg_archival.txt, in case a tarball
  # made by "hg archive" is being used
  if (NOT MTS_REV_ID)
    set(HG_ARCHIVAL_FILENAME "${CMAKE_CURRENT_SOURCE_DIR}/.hg_archival.txt")
    # Try to read from the file generated by "hg archive"
    if (EXISTS "${HG_ARCHIVAL_FILENAME}")
      file(READ "${HG_ARCHIVAL_FILENAME}" HG_ARCHIVAL_TXT)
      # Extract just the first 12 characters of the node
      string(REGEX REPLACE ".*node:[ \\t]+(............).*" "\\1"
        MTS_REV_ID "${HG_ARCHIVAL_TXT}")
      set(MTS_REV_ID ${MTS_REV_ID} PARENT_SCOPE)
    endif()
  endif()

  if (NOT MTS_DATE)
    # The Windows "date" command output depends on the regional settings
    if (WIN32)
      set(GETDATE_CMD "${PROJECT_SOURCE_DIR}/data/windows/getdate.exe")
      set(GETDATE_ARGS "")
    else()
      set(GETDATE_CMD "date")
      set(GETDATE_ARGS "+'%Y.%m.%d'")    
    endif()
    execute_process(COMMAND "${GETDATE_CMD}" ${GETDATE_ARGS}
      OUTPUT_VARIABLE MTS_DATE
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (NOT MTS_DATE)
      #message(FATAL_ERROR "Unable to get a build date!")
    endif()
    set(MTS_DATE ${MTS_DATE} PARENT_SCOPE)
  endif()

  if (MTS_REV_ID)
    set (MTS_HAS_VALID_REV 1)
  else()
    #message(WARNING "Unable to find the mercurial revision id.")
    set (MTS_HAS_VALID_REV 0)
  endif()
  set(MTS_HAS_VALID_REV ${MTS_HAS_VALID_REV} PARENT_SCOPE)


  # Read version (MTS_VERSION) from include/mitsuba/core/version.h
  file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/include/mitsuba/core/version.h" MITSUBA_H REGEX "^#define MTS_VERSION \"[^\"]*\"$")
  if (MITSUBA_H MATCHES "^.*MTS_VERSION \"([0-9]+)\\.([0-9]+)\\.([0-9]+).*$")
    set(MTS_VERSION_MAJOR ${CMAKE_MATCH_1})
    set(MTS_VERSION_MINOR ${CMAKE_MATCH_2})
    set(MTS_VERSION_PATCH ${CMAKE_MATCH_3})
    set(MTS_VERSION "${MTS_VERSION_MAJOR}.${MTS_VERSION_MINOR}.${MTS_VERSION_PATCH}" PARENT_SCOPE)
    set(MTS_VERSION_MAJOR ${MTS_VERSION_MAJOR} PARENT_SCOPE)
    set(MTS_VERSION_MINOR ${MTS_VERSION_MINOR} PARENT_SCOPE)
    set(MTS_VERSION_PATCH ${MTS_VERSION_PATCH} PARENT_SCOPE)
  else()
    message(FATAL_ERROR "The mitsuba version could not be determined!")
  endif()

  # Make a super simple build number from the date
  #if (MTS_DATE MATCHES "([0-9]+)\\.([0-9]+)\\.([0-9]+)")
  if (True)
    set(MTS_VERSION_BUILD
      "${CMAKE_MATCH_1}${CMAKE_MATCH_2}${CMAKE_MATCH_3}" PARENT_SCOPE)

    # Now make a Mac Launch Services version number based on version and date.
    # Based on specs from:
    # http://lists.apple.com/archives/carbon-dev/2006/Jun/msg00139.html (Feb 2011)
    if (MTS_VERSION_MAJOR GREATER 30 OR
        MTS_VERSION_MINOR GREATER 14 OR
        MTS_VERSION_PATCH GREATER 14 OR
        ${CMAKE_MATCH_1} GREATER 2032)
      message(AUTHOR_WARNING "Mitsuba version violates the Mac LS assumptions")
    endif()
    math(EXPR _MACLS_MAJOR "(${MTS_VERSION_MAJOR}+1)*256 + (${MTS_VERSION_MINOR}+1)*16 + ${MTS_VERSION_PATCH}+1")
    math(EXPR _MACLS_MINOR "((${CMAKE_MATCH_1}-2008)*4) + ((${CMAKE_MATCH_2}-1)*32 + ${CMAKE_MATCH_3})/100")
    math(EXPR _MACLS_BUILD "((${CMAKE_MATCH_2}-1)*32 + ${CMAKE_MATCH_3})%100")
    ZERO_PAD(_MACLS_MAJOR 4)
    ZERO_PAD(_MACLS_MINOR 2)
    ZERO_PAD(_MACLS_BUILD 2)
    set(MTS_MACLS_VERSION "${_MACLS_MAJOR}.${_MACLS_MINOR}.${_MACLS_BUILD}")
    if(MTS_HAS_VALID_REV)
      set(MTS_MACLS_VERSION "${MTS_MACLS_VERSION}hg${MTS_REV_ID}")
    endif()
    set(MTS_MACLS_VERSION ${MTS_MACLS_VERSION} PARENT_SCOPE)
  else()
    message(FATAL_ERROR
      "Mitsuba date has an unexpected format: ${MTS_DATE}")
  endif()

endfunction()
