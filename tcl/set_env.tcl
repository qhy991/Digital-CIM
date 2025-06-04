set RTL_FILE        source_file
set working_design  top
set file_version    dc_v1
set do_scan	    0


set RPT_DIR         RPT
set OUT_DIR         OUT

set RPT_OUT  [format "%s%s" $RPT_DIR/ $file_version]
set DATA_OUT [format "%s%s" $OUT_DIR/ $file_version]

set lib_slow     M31GPSC900HI055GR_125CSS1P08_cworst_ccs
set lib_fast     M31GPSC900HI055GR_125CFF1P32_cbest_ccs
set lib_typ       saed90nm_typ


# The following lines create a cmd and log file in the logs directory
#set timestamp [pid].[clock format [clock scan now] -format "%Y-%m-%d_%H-%M"]

#set sh_output_log_file "./logs/${working_design}.log.$timestamp";#shell log file

#set sh_command_log_file "./logs/${working_design}.cmd.$timestamp" AdderTree_wrapper
