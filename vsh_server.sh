declare -r mode=$1
declare -r args=$2
declare -r archives="archives" ##archive by default

function archive_existe() {
if [[ -f "archives/$1" ]]; then
return 0
else
return 1
fi
}

fucntion check_archive() {
if ! archive_existe $1; then
echo "Archive '$1' does not exist, please enter another archive"
exit 1
fi
}

function list() {
tree $archives
}

function browse() {
bash browse.sh $1
}

function extract() {

}

if [ $mode == "list" ]; then
list
elif [ $mode == "extract" ]; then
arch=$(echo $args | cut -d ' ' -f1)
if ! archive_exists $arch; then
echo -e "\nVSH_EXTRACT_UNK_ARCH"
echo -e "\nno archive named $arch"
exit 1
fi
cat "$archive_dir/$arch"
echo -e "\nVSH_END_EXTRACT"
elif [ $mode == "browse" ]; then
arch=$(echo $args | cut -d ' ' -f1)
browse $arch
elif [ $mode == "exit" ]; then
exit 0
fi
