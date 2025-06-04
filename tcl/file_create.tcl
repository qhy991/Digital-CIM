
if {[file exist $RPT_DIR]} {
    echo "File $RPT_DIR already exist"
} else {
    exec mkdir $RPT_DIR
    echo "Creating $RPT_DIR !!!"
}

if {[file exist $RPT_DIR/$file_version]} {
    echo "File $file_version already exist"
    exec rm $RPT_DIR/$file_version -r
    exec mkdir $RPT_DIR/$file_version
    echo "Re-create $file_version files"
} else {
    exec mkdir $RPT_DIR/$file_version
    echo "Creating $file_version in $RPT_DIR !!!"
}


if {[file exist $OUT_DIR]} {
    echo "File $OUT_DIR already exist"
} else {
    exec mkdir $OUT_DIR
    echo "Creating $OUT_DIR !!!"
}

if {[file exist $OUT_DIR/$file_version]} {
    echo "File $file_version already exist"
    exec rm $OUT_DIR/$file_version -r
    exec mkdir $OUT_DIR/$file_version
    echo "Re-create $file_version files"
} else {
    exec mkdir $OUT_DIR/$file_version
    echo "Creating $file_version in $OUT_DIR !!!"
}

# create work
if {[file exist WORK]} {
    echo "File WORK already exist"
} else {
    exec mkdir WORK
    echo "Creating WORK!!!"
}

if {[file exist WORK/$file_version]} {
    echo "File WORK/$file_version already exist"
} else {
    exec mkdir WORK/$file_version
    echo "Creating WORK/$file_version in WORK !!!"
}

